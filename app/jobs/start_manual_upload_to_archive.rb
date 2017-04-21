class StartManualUploadToArchive < BaseJob
   require 'fileutils'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)

      raise "Parameter 'user_id' is required" if message[:user_id].blank?
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      unit = Unit.find( message[:unit_id])
      src_dir = File.join(MANUAL_UPLOAD_TO_ARCHIVE_DIR_PRODUCTION, unit.directory)

      if not File.exist? src_dir
         on_error "Manual upload directory #{src_dir} does not exist."
      end

      in_process_dir = File.join(IN_PROCESS_DIR, unit.directory)
      logger().info "Moving Manual upload directory for unit #{unit.id} to #{in_process_dir}"
      FileUtils.mv(src_dir, in_process_dir)

      contents = Dir.entries(in_process_dir).delete_if {|x| x == "." or x == ".." or x == ".AppleDouble" or x == ".DS_Store"}
      if contents.empty?
         on_success "No items to upload in #{in_process_dir}"
         return
      end

      archive_dir = File.join(ARCHIVE_DIR, unit.directory);
      if !Dir.exists? archive_dir
         logger().info "Creating archive dir #{archive_dir}"
         FileUtils.mkdir_p(archive_dir)
         FileUtils.chmod(0775, archive_dir)
      end

      error = false
      contents.each do |filename|
         src_file = File.join(in_process_dir, filename)

         dest_file = File.join(archive_dir, filename)
         logger().info "Archiving #{dest_file}"
         FileUtils.copy(src_file, dest_file)
         FileUtils.chmod(0664, dest_file)

         src_md5 = Digest::MD5.hexdigest(File.read(src_file) )
         dest_md5 = Digest::MD5.hexdigest(File.read(dest_file) )
         if src_md5 != dest_md5
            error = true
            on_failure("** Warning ** - File #{dest_file} has failed checksum test")
         end
      end
      if error
         on_error "There were errors with the archiving process"
      else
         logger().info "Updating date archived"
         unit.update(date_archived: Time.now)
         unit.master_files.each do |mf|
            mf.update(date_archived: Time.now)
         end

         del_dir = File.join(DELETE_DIR_FROM_STORNEXT, unit.directory)
         logger().info "Moving to #{del_dir}"
         FileUtils.mv(in_process_dir, del_dir)
      end
   end
end
