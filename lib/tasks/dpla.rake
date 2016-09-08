require "#{Rails.root}/app/helpers/dpla_helper"
include DplaHelper

namespace :dpla do
   desc "Generate DPLA METS/MODS for a parent bibl ID"
   task :generate  => :environment do
      id = ENV['id']
      abort("id is required") if id.nil?

      mods_dir = "#{Settings.delivery_dir}/dpla/mods"
      abort("Mods delivery dir #{mods_dir} does not exist") if !Dir.exist? mods_dir
      mets_dir = "#{Settings.delivery_dir}/dpla/mets"
      abort("Mets delivery dir #{mets_dir} does not exist") if !Dir.exist? mets_dir

      metadata = Metadata.find_by(id: id)
      abort("ID is invalid") if metadata.nil?
      sirsi_meta = metadata.becomes(SirsiMetadata)

      xsl = File.join(Rails.root, "lib", "xslt", "DPLA", "MODStoDPLAMODS.xsl")
      saxon = "java -jar #{File.join(Rails.root, "lib", "Saxon-HE-9.7.0-8.jar")}"

      puts "Generate DPLA MODS XML for all children of #{metadata.pid}..."
      pid_paths = {}
      sirsi_meta.child_bibls.each do |b|
         puts "     Child PID: #{b.pid}"
         src = "#{Settings.tracksys_url}/api/metadata/#{b.pid}?type=desc_metadata"
         relative_pid_path = relative_pid_path(b.pid)
         pid_path = File.join(mods_dir, relative_pid_path)
         pid_paths[b.pid] = relative_pid_path
         FileUtils.mkdir_p pid_path if !Dir.exist?(pid_path)
         out = File.join(pid_path, "#{b.pid}.xml")

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
      out = "#{mets_dir}/#{metadata.pid}.xml"
      mods_xml = ApplicationController.new.render_to_string(
         :template => 'template/mets.xml',
         :locals => { metadata: sirsi_meta }
      )
      outf = File.open(out, "w")
      outf << mods_xml
      outf.close
      puts "DONE"
   end
end
