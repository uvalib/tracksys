class StartManualUploadToArchive < BaseJob
   require 'fileutils'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"StaffMember", :originator_id=>message[:user_id])
   end

   def do_workflow(message)

      raise "Parameter 'directory' is required" if message[:directory].blank?

      now = Time.now
      day = now.strftime("%A")
      regex_unit = Regexp.new('\d{9}$')
      directory = message[:directory]
      in_process_directory = File.join(directory, "in_process")

      if not File.exist?(File.join(directory, day))
         on_error "Manual upload directory #{directory}/#{day} does not exist."
      else
         original_source_dir = File.join(directory, day)
         contents = Dir.entries(original_source_dir).delete_if {|x| x == "." or x == ".."}

         if contents.empty?
            on_success "No items to upload in #{original_source_dir}"
         else
            # Process each value in array
            contents.each do |content|
               complete_path = File.join(original_source_dir, content)
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
                     FileUtils.mv File.join(original_source_dir, content), File.join(in_process_directory, content)

                     if regex_unit.match(content).nil?
                        SendUnitToArchive.exec_now({:unit_dir => content, :internal_dir => false, :source_dir => in_process_directory}, self)
                        on_success "Non-Tracking System managed content (#{content}) sent to archive via manual upload directory from #{directory}/#{day}."
                     else
                        unit_id = content.to_s.sub(/^0+/, '')
                        unit = Unit.find(unit_id)
                        SendUnitToArchive.exec_now( {:unit => unit, :unit_dir => content, :internal_dir => true, :source_dir => in_process_directory}, self)
                        on_success "Unit #{unit_id} sent to StorNext workflow via manual upload directory from #{directory}/#{day}."
                     end
                  end
               end
            end
         end
      end
   end
end
