namespace :dpla do
   desc "Generate DPLA METS/MODS for a parent bibl ID"
   task :generate  => :environment do
      id = ENV['id']
      abort("id is required") if id.nil?
      ws_url = ENV['ws_url']
      abort("ws_url is required") if ws_url.nil?
      dest = ENV['dest']
      abort("dest is required") if dest.nil?
      mods_dir = "#{dest}/mods"
      FileUtils.mkdir_p mods_dir if !Dir.exist? mods_dir
      mets_dir = "#{dest}/mets"
      FileUtils.mkdir_p mets_dir if !Dir.exist? mets_dir

      metadata = Metadata.find_by(id: id)
      abort("ID is invalid") if metadata.nil?
      sirsi_meta = metadata.becomes(SirsiMetadata)

      xsl = File.join(Rails.root, "lib", "xslt", "DPLA", "MODStoDPLAMODS.xsl")
      saxon = "java -jar #{File.join(Rails.root, "lib", "Saxon-HE-9.7.0-8.jar")}"

      puts "Generate DPLA MODS XML for all children of #{metadata.pid}..."
      sirsi_meta.child_bibls.each do |b|
         puts "     Child PID: #{b.pid}"
         src = "#{Settings.tracksys_url}/api/metadata/#{b.pid}?type=desc_metadata"
         out = get_mods_dir(mods_dir, b.pid)

         params = "pid=#{b.pid}"
         if b.exemplar.blank?
            emf = b.master_files.first
         else
            emf = MasterFile.find_by(filename: b.exemplar)
         end
         abort("No exemplar set for metadata record") if emf.nil?
         params << " exemplarPid=#{emf.pid}"

         cmd = "     #{saxon} -s:#{src} -xsl:#{xsl} -o:#{out} #{params}"
         puts cmd
         `#{cmd}`
      end

      puts "Generate DPLA METS XML for MODS..."
      out = "#{mets_dir}/#{metadata.pid.gsub(/:/,"_")}.xml"
      mods_xml = ApplicationController.new.render_to_string(
         :template => 'template/mets.xml',
         :locals => { metadata: sirsi_meta, ws_url: ws_url }
      )
      outf = File.open(out, "w")
      outf << mods_xml
      outf.close
      puts "DONE"
   end

   # FIXME
   def get_mods_dir( mods_dir, pid )
      # out_dir = "#{mods_dir}/#{metadata.pid.gsub(/:/,"_")}"
      # FileUtils.mkdir_p out_dir if !Dir.exist? out_dir
      # out = "#{out_dir}/#{b.pid.gsub(/:/,"_")}.xml"
      pid_parts = pid.split(":")
      base = pid_parts[1]
      parts = base.scan(/../) # break up into 2 digit sections, but this leaves off last char if odd
      parts << base.last if parts.length * 2 !=  base.length
      pid_dirs = parts.join("/")
      xml_filename = "#{pid.gsub(/:/,"_")}.xml"
      xml_path = File.join(mods_dir, pid_parts[0], pid_dirs)
      FileUtils.mkdir_p xml_path if !Dir.exist?(xml_path)
      return File.join(xml_path, xml_filename)
   end
end
