class CopyArchivedFilesToProduction < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)

      # There are two kinds of messages sent to this processor:
      # 1. Download one master file
      # 2. Download all master files for a unit
      # All messages will include a unit_id.

      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'computing_id' is required" if message[:computing_id].blank?

      unit = Unit.find(message[:unit_id])
      computing_id = message[:computing_id]
      unit_dir = "%09d" % unit.id
      failure_messages = Array.new

      source_dir = File.join(ARCHIVE_DIR, unit_dir)
      destination_dir = File.join(Finder.scan_from_archive_dir, computing_id)
      FileUtils.mkdir_p(destination_dir)
      FileUtils.chmod 0775, "#{destination_dir}"

      if message[:master_file_filename]
         master_file_filename = message[:master_file_filename]
         begin
            FileUtils.cp(File.join(source_dir, master_file_filename), File.join(destination_dir, master_file_filename))
            File.chmod(0666, File.join(destination_dir, master_file_filename))
         rescue Exception => e
            failure_messages << "Can't copy source file '#{master_file_filename}': #{e.message}"
         end

         # compare MD5 checksums
         source_md5 = Digest::MD5.hexdigest(File.read(File.join(source_dir, master_file_filename)))
         dest_md5 = Digest::MD5.hexdigest(File.read(File.join(destination_dir, master_file_filename)))
         if source_md5 != dest_md5
            failure_messages << "Failed to copy source file '#{master_file_filename}': MD5 checksums do not match"
         end
      else
         unit.master_files.each do |master_file|
            begin
               FileUtils.cp(File.join(source_dir, master_file.filename), File.join(destination_dir, master_file.filename))
               File.chmod(0664, File.join(destination_dir, master_file.filename))
               # FileUtils.chown(nil, 'lb-ds', File.join(destination_dir, master_file.filename))
            rescue Exception => e
               failure_messages << "Can't copy source file '#{master_file.filename}': #{e.message}"
            end

            # compare MD5 checksums
            source_md5 = Digest::MD5.hexdigest(File.read(File.join(source_dir, master_file.filename)))
            dest_md5 = Digest::MD5.hexdigest(File.read(File.join(destination_dir, master_file.filename)))
            if source_md5 != dest_md5
               failure_messages << "Failed to copy source file '#{master_file.filename}': MD5 checksums do not match"
            end
         end

         if File.exist?(File.join(source_dir, "#{unit_dir}.ivc"))
            FileUtils.cp(File.join(source_dir, "#{unit_dir}.ivc"), File.join(destination_dir, "#{unit_dir}.ivc"))
            File.chmod(0664, File.join(destination_dir, "#{unit_dir}.ivc"))
         end
         if File.exist?(File.join(source_dir, "#{unit_dir}.mpcatalog"))
            FileUtils.cp(File.join(source_dir, "#{unit_dir}.mpcatalog"), File.join(destination_dir, "#{unit_dir}.mpcatalog"))
            File.chmod(0664, File.join(destination_dir, "#{unit_dir}.mpcatalog"))
         end
         if File.exist?(File.join(source_dir, "#{unit_dir}.xml"))
            FileUtils.cp(File.join(source_dir, "#{unit_dir}.xml"), File.join(destination_dir, "#{unit_dir}.xml"))
            File.chmod(0664, File.join(destination_dir, "#{unit_dir}.xml"))
         end
      end

      if failure_messages.empty?
         if master_file_filename
            logger.info "Master file #{master_file_filename} from unit #{unit.id} has been successfully copied to #{destination_dir}."
         else
            logger.info "All master files from unit #{unit.id} have been successfully copied to #{destination_dir}."
         end
      else
         failure_messages.each do |message|
            log_failure "#{message}"
         end
         fatal_error "There were failures in the copying process."
      end
   end
end
