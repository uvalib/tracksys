require "#{Rails.root}/app/helpers/dpla_helper"
include DplaHelper

namespace :dpla do
   desc "Generate DPLA METS/MODS for a parent metadata ID"
   task :generate_all  => :environment do
      # FIXME: instead of the hardcoded list, do this:
      # Get all parent metadata records that are published to virgo and flagged for Dpla...
      #
      # select distinct mp.id,mp.type,mp.dpla,mp.date_dl_ingest from metadata mc
      # inner join metadata mp on mc.parent_metadata_id = mp.id
      # where mc.parent_metadata_id <> '' and mp.dpla = 1 and mp.date_dl_ingest is not null
      # order by mp.id asc;
      #
      ids = ["3002", "3009", "3109", "6405", "15784"]
      overwrite = (ENV['force'] == "1" || ENV['force'] == "yes" || ENV['force'] == "true")
      id.each do |id|
         puts "===> GENERATE #{id}"
         ENV['id'] = id
         ENV['force'] = overwrite
         Rake::Task['dpla:generate'].execute
      end
   end

   task test: :environment do
      qdc_dir = "tmp/dpla/qdc"

      puts "Reading QDC xml template..."
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      overwrite = (ENV['force'] == "1" || ENV['force'] == "yes" || ENV['force'] == "true")
      puts "Overwrite existing records? #{overwrite}"

      # Metadata.find(3009).children.each do |meta|
      Metadata.where(pid: "uva-lib:1051234").each do |meta|
         next if !meta.dpla
         puts "Process #{meta.pid}..."

         # determine where to put output file (split pid up into 3 digit segments to avoid massive directory listing)
         relative_pid_path = relative_pid_path(meta.pid)
         pid_path = File.join(qdc_dir, relative_pid_path)
         FileUtils.mkdir_p pid_path if !Dir.exist?(pid_path)
         qdc_fn = File.join(pid_path, "#{meta.pid}.xml")
         if !overwrite && File.exists?(qdc_fn)
            puts "File #{qdc_fn} exists and not in overwrite mode. Skipping."
            next
         end

         # ingest into an XML document and do a manual crosswalk to get data
         doc = Nokogiri::XML( Hydra.desc(meta) )
         doc.remove_namespaces!
         cw_data = {}
         cw_data['TITLE'] = meta.title
         cw_data['RIGHTS'] = meta.use_right.uri
         cw_data['TERMS'] = []

         # Creator Name
         # in this order: usage=primary, personal, first one
         cn  = doc.at_xpath("//name[@usage='primary']")
         cn = doc.at_xpath("//name[@type='personal']") if cn.blank?
         cn = doc.at_xpath("//name") if cn.blank?
         if !cn.blank?
            cw_data['CREATOR'] = ""
            cn.xpath("namePart").each do |n|
               cw_data['CREATOR'] << " " if cw_data['CREATOR'].length > 0
               cw_data['CREATOR'] << n.text
            end
         end

         # Date Created
         n = doc.at_xpath("//originInfo/dateCreated[@keyDate='yes']")
         n = doc.at_xpath("//originInfo/mods:dateIssued") if n.nil?
         if !n.nil?
            cw_data['TERMS'] << "<dcterms:created>#{n.text}</dcterms:created>" if n.text != "undated"
         end

         cw_data['TERMS'] << crosswalk(doc, "//identifier[@type='accessionNumber']", "identifier")
         cw_data['TERMS'] << crosswalk(doc, "//abstract", "description")
         cw_data['TERMS'] << crosswalk(doc, "//physicalDescription/form", "medium")
         cw_data['TERMS'] << crosswalk(doc, "//physicalDescription/extent", "extent")
         cw_data['TERMS'] << crosswalk(doc, "//language/languageTerm", "language")
         cw_data['TERMS'] << crosswalk(doc, "//originInfo/publisher", "publisher")
         cw_data['TERMS'] << crosswalk(doc, "//subject/topic", "subject")
         cw_data['TERMS'] << crosswalk(doc, "//subject/name", "subject")
         cw_data['TERMS'] << crosswalk(doc, "//typeOfResource", "type")
         cw_data['TERMS'] << crosswalk(doc, "//relatedItem[@type='series'][@displayLabel='Part of']/titleInfo/title", "isPartOf")

         # <subject><hierarchicalGeographic> -> dcterms:spatial
         nd = doc.at_xpath("//subject/hierarchicalGeographic")
         if !nd.nil?
            out = ""
            ["country", "state", "city"].each do |t|
               p = doc.at_xpath("//subject/hierarchicalGeographic/#{t}")
               if !p.nil?
                  out << ", " if out.length > 0
                  out << p.text
               end
            end
            if out.length > 0
               cw_data['TERMS'] << "<dcterms:spatial>#{out}</dcterms:spatial>"
            end
         end

         cw_data['TERMS'].compact!
         qdc = qdc_tpl.gsub(/PID/, meta.pid)
         cw_data.each do |k,v|
            if k == "TERMS"
               qdc.gsub!(/#{k}/, v.join("\n    "))
            else
               qdc.gsub!(/#{k}/, v)
            end
         end

         # write QDC file to filesystem

         out = File.open(qdc_fn, "w")
         out.write(qdc)
         out.close

         abort("ONE")
      end
   end

   def crosswalk(doc, xpath, qdc_ele)
      n = doc.at_xpath(xpath)
      if !n.nil?
         return "<dcterms:#{qdc_ele}>#{n.text.strip}</dcterms:#{qdc_ele}>"
      end
      return nil
   end

   desc "Generate DPLA METS/MODS for a parent metadata ID"
   task :generate  => :environment do
      id = ENV['id']
      abort("id is required") if id.nil?

      mods_dir = "#{Settings.delivery_dir}/dpla/mods"
      abort("Mods delivery dir #{mods_dir} does not exist") if !Dir.exist? mods_dir
      mets_dir = "#{Settings.delivery_dir}/dpla/mets"
      abort("Mets delivery dir #{mets_dir} does not exist") if !Dir.exist? mets_dir

      metadata = Metadata.find_by(id: id)
      abort("ID is invalid") if metadata.nil?
      abort("Not available for DPLA") if !metadata.dpla

      # Only regenerate mods files if force flag
      overwrite = (ENV['force'] == "1" || ENV['force'] == "yes" || ENV['force'] == "true")

      xsl = File.join(Rails.root, "lib", "xslt", "DPLA", "MODStoDPLAMODS.xsl")
      saxon = "java -jar #{File.join(Rails.root, "lib", "Saxon-HE-9.7.0-8.jar")}"

      # Is this a DPLA collection record (a record that has children)?
      child_info = []
      if metadata.children.size > 0
         puts "Generate DPLA MODS XML for all children of #{metadata.pid}..."
         metadata.children.each do |b|
            next if !b.dpla

            puts "     Child PID: #{b.pid}"

            # determine where to put output file
            relative_pid_path = relative_pid_path(b.pid)
            pid_path = File.join(mods_dir, relative_pid_path)
            FileUtils.mkdir_p pid_path if !Dir.exist?(pid_path)
            out = File.join(pid_path, "#{b.pid}.xml")
            if File.exist?(out) && File.size(out) > 0 && overwrite == false
               puts "          MODS file already exists; SKIPPING"
               next
            end

            # write desc metadata out to temp file
            desc_xml_file = Tempfile.new([b.pid, "xml"])
            src = desc_xml_file.path
            begin
               desc_xml_file.write(Hydra.desc(b))
               desc_xml_file.close

               params = "pid=#{b.pid}"
               if b.exemplar.blank?
                  emf = b.master_files.first
               else
                  emf = MasterFile.find_by(filename: b.exemplar)
               end
               raise("No exemplar set for metadata record. Skipping #{b.pid}") if emf.nil?
               params << " exemplarPid=#{emf.pid}"
               child_info << { pid: b.pid, exemplar: emf.pid }

               cmd = "     #{saxon} -s:#{src} -xsl:#{xsl} -o:#{out} #{params}"
               `#{cmd}`
            rescue Exception => e
               puts "          SKIPPING #{b.pid} ERROR: #{e.message}"
               bt = e.backtrace.join("\n")
               puts "          #{bt}"
            end

            desc_xml_file.unlink
         end
      else
         # Not collection record. Generate MODS from master file metadata
         # Skip if masterfile is not discoverable.
         # Also skip all master files for units that are not in the DL
         puts "Generate DPLA MODS XML for all Masterfiles from DL units of #{metadata.pid}..."
         metadata.units.each do |u|
            # Not in DL; don't care about it
            next if !u.include_in_dl

            puts "  Unit #{u.id} is included in DL. Finding master files..."
            u.master_files.each do |mf|
               # The MF metadata must be discoverable, and have this MF
               # as its only child
               next if !mf.discoverability
               next if mf.metadata.type != "XmlMetadata"
               next if mf.metadata.master_files.size > 1
               next if mf.metadata.master_files.first != mf

               puts "     Master File PID: #{mf.pid}"
               tmp = Tempfile.new(mf.pid)
               tmp.write(mf.metadata.desc_metadata)
               tmp.close
               relative_pid_path = relative_pid_path(mf.pid)
               pid_path = File.join(mods_dir, relative_pid_path)
               FileUtils.mkdir_p pid_path if !Dir.exist?(pid_path)
               out = File.join(pid_path, "#{mf.pid}.xml")

               params = "pid=#{mf.pid} exemplarPid=#{mf.pid}"
               child_info << { pid: mf.pid, exemplar: mf.pid }

               cmd = "#{saxon} -s:#{tmp.path} -xsl:#{xsl} -o:#{out} #{params}"
               puts "     #{cmd}"
               `#{cmd}`
               tmp.unlink
            end
         end
      end

      puts "Generate DPLA METS XML from child PIDs..."
      out = "#{mets_dir}/#{metadata.pid}.xml"
      mods_xml = ApplicationController.new.render_to_string(
         :template => 'template/mets.xml',
         :locals => { parent_pid: metadata.pid, child_info: child_info }
      )
      outf = File.open(out, "w")
      outf << mods_xml
      outf.close
      puts "DONE"
   end
end
