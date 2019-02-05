class AttachFile < BaseJob
   require 'fileutils'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'filename' is required" if message[:filename].blank?
      raise "Parameter 'tmpfile' is required" if message[:tmpfile].blank?

      unit = message[:unit]
      filename = message[:filename]
      unit_dir = "%09d" % unit.id
      dest_dir = File.join(ARCHIVE_DIR, unit_dir, "attachments" )
      if !Dir.exist? dest_dir
         FileUtils.mkdir_p(dest_dir)
         FileUtils.chmod(0775, dest_dir)
      end

      logger.info "Creating MD5 checksum of uploaded file #{message[:tmpfile]}"
      md5 = Digest::MD5.hexdigest(File.read(message[:tmpfile]) )

      dest_file = File.join(dest_dir, filename)
      logger.info "Archiving attachment to #{dest_file}"
      FileUtils.cp(message[:tmpfile], dest_file)
      FileUtils.chmod(0664, dest_file)
      md5_cp = Digest::MD5.hexdigest(File.read(dest_file))

      if md5 != md5_cp
         log_failure("Checksum of archived file does not match original")
      end

      logger.info "Creating attachment record"
      att = Attachment.create(unit: unit, description: message[:description], md5: md5, filename: filename)
      if att.nil?
         log_failure "Unable to save attachment: #{att.errors.full_messages.to_sentence}"
      end

      on_success "File #{filename} added as attachment"
   end
end
