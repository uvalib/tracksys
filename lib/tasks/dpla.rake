namespace :dpla do
   desc "Generate DPLA QDC for all collection records"
   task :generate_all  => :environment do
      overwrite = (ENV['force'] == "1" || ENV['force'] == "yes" || ENV['force'] == "true")
      q = "select distinct mp.id, mp.title from metadata mc"
      q << " inner join metadata mp on mc.parent_metadata_id = mp.id"
      q << " where mc.parent_metadata_id <> '' and mp.dpla = 1 and mp.date_dl_ingest is not null"
      q << " order by mp.id asc"
      Metadata.find_by_sql(q).each do |m|
         puts "===> Processing #{m.id}: #{m.title}"
         ENV['id'] = m.id.to_s
         ENV['force'] = overwrite.to_s
         # ENV['cnt'] = "1"
         Rake::Task['dpla:generate'].execute
      end
   end

   desc "Generate DPLA QDC for a single collection record"
   task generate: :environment do
      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      abort("QDC delivery dir #{qdc_dir} does not exist") if !Dir.exist? qdc_dir

      metadata_id = ENV['id']
      abort("ID is required!") if metadata_id.nil?

      overwrite = (ENV['force'] == "1" || ENV['force'] == "yes" || ENV['force'] == "true")
      puts "Overwrite existing records? #{overwrite}"

      max_cnt = ENV['cnt']
      if max_cnt.nil?
         max_cnt = -1
      else
         puts "Test: limit generation to #{max_cnt} records"
         max_cnt = max_cnt.to_i
      end

      puts "Reading QDC xml template..."
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      cnt = 0
      Metadata.find(metadata_id).children.each do |meta|
         next if !meta.dpla
         puts "Process #{meta.id}:#{meta.pid}..."

         # determine where to put output file (split pid up into 3 digit segments to avoid massive directory listing)
         relative_pid_path = QDC.relative_pid_path(meta.pid)
         pid_path = File.join(qdc_dir, relative_pid_path)
         FileUtils.mkdir_p pid_path if !Dir.exist?(pid_path)
         qdc_fn = File.join(pid_path, "#{meta.pid}.xml")
         if !overwrite && File.exists?(qdc_fn)
            puts "File #{qdc_fn} exists and not in overwrite mode. Skipping."
            next
         end

         exemplar_pid = meta.master_files.first.pid
         if !meta.exemplar.blank?
            exemplar = meta.master_files.find_by(filename: meta.exemplar)
            if !exemplar.nil?
               exemplar_pid = exemplar.pid
            end
         end

         # ingest into an XML document and do a manual crosswalk to get data
         doc = Nokogiri::XML( Hydra.desc(meta) )
         doc.remove_namespaces!
         cw_data = {}
         cw_data['EXEMPLAR'] = exemplar_pid
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
               cw_data['CREATOR'] << QDC.clean_xml_text(n.text)
            end
         end

         # Date Created
         n = doc.at_xpath("//originInfo/dateCreated[@keyDate='yes']")
         n = doc.at_xpath("//originInfo/dateIssued") if n.nil?
         if !n.nil?
            cw_data['TERMS'] <<
               "<dcterms:created>#{QDC.clean_xml_text(n.text)}</dcterms:created>" if n.text != "undated"
         end

         cw_data['TERMS'] << QDC.crosswalk(doc, "//identifier[@type='accessionNumber']", "identifier")
         cw_data['TERMS'] << QDC.crosswalk(doc, "//abstract", "description")
         cw_data['TERMS'] << QDC.crosswalk(doc, "//physicalDescription/form", "medium")
         cw_data['TERMS'] << QDC.crosswalk(doc, "//physicalDescription/extent", "extent")
         cw_data['TERMS'] << QDC.crosswalk(doc, "//language/languageTerm", "language")
         cw_data['TERMS'] << QDC.crosswalk(doc, "//originInfo/publisher", "publisher")
         cw_data['TERMS'] << QDC.crosswalk(doc, "//subject/topic", "subject")
         cw_data['TERMS'] << QDC.crosswalk(doc, "//subject/name", "subject")
         cw_data['TERMS'] << QDC.crosswalk(doc, "//typeOfResource", "type")
         cw_data['TERMS'] << QDC.crosswalk(doc, "//relatedItem[@type='series'][@displayLabel='Part of']/titleInfo/title", "isPartOf")

         # <subject><hierarchicalGeographic> -> dcterms:spatial
         nd = doc.at_xpath("//subject/hierarchicalGeographic")
         if !nd.nil?
            out = ""
            ["country", "state", "city"].each do |t|
               p = doc.at_xpath("//subject/hierarchicalGeographic/#{t}")
               if !p.nil?
                  out << ", " if out.length > 0
                  out << QDC.clean_xml_text(p.text)
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

         cnt += 1
         if max_cnt > -1 && cnt == max_cnt
            puts "Stopping after #{cnt}"
            break
         end
      end
   end
end
