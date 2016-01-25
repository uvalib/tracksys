class StartManualUploadToArchiveProduction < BaseJob
   require 'fileutils'

   def perform(message)
      Job_Log.debug "StartManualUploadToArchiveProductionProcessor received: #{message.to_json}"

      now = Time.now
      day = now.strftime("%A")
      regex_unit = Regexp.new('\d{9}$')
      @user_id = message[:user_id]
      set_workflow_type()

      if not File.exist?(File.join(MANUAL_UPLOAD_TO_ARCHIVE_DIR_PRODUCTION, day))
         on_error "Manual upload directory #{MANUAL_UPLOAD_TO_ARCHIVE_DIR_PRODUCTION}/#{day} does not exist."
      else
         @original_source_dir = File.join(MANUAL_UPLOAD_TO_ARCHIVE_DIR_PRODUCTION, day)
         contents = Dir.entries(@original_source_dir).delete_if {|x| x == "." or x == ".."}

         if contents.empty?
            on_success "No items to upload in #{@original_source_dir}"
         else
            # Process each value in array
            contents.each do |content|
               complete_path = File.join(@original_source_dir, content)
               # Directory test
               if not File.directory?(complete_path)
                  if /DS_Store/ =~ content
                     # skip
                  else
                     on_failure "#{complete_path} is not a directory"
                  end
               else
                  # We are going to skp naming format test here to allow non-DSSR produced material
                  # Empty directory test
                  if (Dir.entries(complete_path) == [".", ".."])
                     on_failure "#{complete_path} is an empty directory"
                  else
                     # Move directory from 'day' directory to 'in_process' directory to prevent staff from accidentally archiving the material twice in quick succession.
                     FileUtils.mv File.join(@original_source_dir, content), File.join(MANUAL_ARCHIVE_IN_PROCESS_DIR_PRODUCTION, content)

                     if regex_unit.match(content).nil?
                        @messagable_type = "StaffMember"
                        @messagable_id = @user_id
                        @internal_dir = "no"
                        on_success "Non-Tracking System managed content (#{content}) sent to StorNext worklfow via manual upload directory from #{MANUAL_UPLOAD_TO_ARCHIVE_DIR_PRODUCTION}/#{day}."
                        SendUnitToArchive.exec_now({:unit_dir => content, :source_dir => MANUAL_ARCHIVE_IN_PROCESS_DIR_PRODUCTION, :internal_dir => @internal_dir})
                     else
                        @internal_dir = "yes"
                        @unit_id = content.to_s.sub(/^0+/, '')
                        @messagable_id = @unit_id
                        @messagable_type = "Unit"
                        on_success "Unit #{@unit_id} sent to StorNext workflow via manual upload directory from #{MANUAL_UPLOAD_TO_ARCHIVE_DIR_PRODUCTION}/#{day}."
                        SendUnitToArchive.exec_now( { :unit_id => @unit_id, :unit_dir => content, :source_dir => MANUAL_ARCHIVE_IN_PROCESS_DIR_PRODUCTION, :internal_dir => @internal_dir})
                     end
                  end
               end
            end
         end
      end
   end
end
