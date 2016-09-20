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
            desc_xml_file.write(Hydra.desc(b))
            desc_xml_file.close

            params = "pid=#{b.pid}"
            if b.exemplar.blank?
               emf = b.master_files.first
            else
               emf = MasterFile.find_by(filename: b.exemplar)
            end
            abort("No exemplar set for metadata record") if emf.nil?
            params << " exemplarPid=#{emf.pid}"
            child_info << { pid: b.pid, exemplar: emf.pid }

            cmd = "     #{saxon} -s:#{src} -xsl:#{xsl} -o:#{out} #{params}"
            `#{cmd}`
            desc_xml_file.unlink
         end
      else
         # Not collection record. Generate MODS from master file desc_metadata
         # Skip if masterfile does not have desc_metadata or is not discoverable.
         # Also skip all master files for units that are not in the DL
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
