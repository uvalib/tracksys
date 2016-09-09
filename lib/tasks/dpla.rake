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
      abort("Not available for DPLA") if !metadata.dpla

      xsl = File.join(Rails.root, "lib", "xslt", "DPLA", "MODStoDPLAMODS.xsl")
      saxon = "java -jar #{File.join(Rails.root, "lib", "Saxon-HE-9.7.0-8.jar")}"

      # Is this a DPLA collection record (a record that has children)?
      if metadata.children.size > 0
         puts "Generate DPLA MODS XML for all children of #{metadata.pid}..."
         metadata.children.each do |b|
            puts "     Child PID: #{b.pid}"
            src = "#{Settings.tracksys_url}/api/metadata/#{b.pid}?type=desc_metadata"
            relative_pid_path = relative_pid_path(b.pid)
            pid_path = File.join(mods_dir, relative_pid_path)
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

         puts "Generate DPLA METS XML from metadata MODS..."
         out = "#{mets_dir}/#{metadata.pid}.xml"
         mods_xml = ApplicationController.new.render_to_string(
            :template => 'template/mets.xml',
            :locals => { metadata: metadata }
         )
         outf = File.open(out, "w")
         outf << mods_xml
         outf.close
      else
         # Not collection record. Assume all masterfiles have MODS desc_metadata
         puts "Generate DPLA MODS XML for all Masterfiles from DL units of #{metadata.pid}..."
         metadata.units.each do |u|
            next if !u.include_in_dl
            puts "  Unit #{u.id} is included in DL. Finding master files..."
            u.master_files.each do |mf|
               next if mf.desc_metadata.blank? || !mf.discoverability
               puts "     Master File PID: #{mf.pid}"
               tmp = Tempfile.new(mf.pid)
               tmp.write(mf.desc_metadata)
               tmp.close
               relative_pid_path = relative_pid_path(mf.pid)
               pid_path = File.join(mods_dir, relative_pid_path)
               FileUtils.mkdir_p pid_path if !Dir.exist?(pid_path)
               out = File.join(pid_path, "#{mf.pid}.xml")

               params = "pid=#{mf.pid} exemplarPid=#{mf.pid}"

               cmd = "#{saxon} -s:#{tmp.path} -xsl:#{xsl} -o:#{out} #{params}"
               puts "     #{cmd}"
               `#{cmd}`
               tmp.unlink
            end
         end

         puts "Generate DPLA METS XML from masterfile MODS..."
         # metadata.unit.master_files.each do |mf|
         # end
      end
      puts "DONE"
   end
end
