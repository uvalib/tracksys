class StartFinalization < BaseJob
   require 'fileutils'

   def perform(message)
      Job_Log.debug("StartFinalization received: #{message.to_json}")

      raise "Parameter 'directory' is required" if message[:directory].blank?

      regex_unit = Regexp.new('(\d{9}$)')

      finalization_dir = message[:directory]
      @messagable_type = "Unit"
      set_workflow_type()

      # Check that the mounts are up and the directory that holds the files still exists.
      if not File.exist?(finalization_dir)
         on_failure "#{finalization_dir} directory does not exist.  Check mounts to NetApps."
      else
         contents = Dir.entries(finalization_dir).delete_if {|x| x == "." or x == ".." or x == ".AppleDouble" }

         # Check that there is content in the finalization directory
         if contents.empty?
            on_failure "No items to finalize in #{finalization_dir}"
         else
            contents.each do |content|
               if not /DS_Store/ =~ content and not content == ".AppleDouble"
                  complete_path = File.join(finalization_dir, content)
                  # Everything in the finalization directory must be a directory
                  if not File.directory?(complete_path)
                     on_error "#{complete_path} is not a directory"
                  else
                     # Empty directory test
                     if (Dir.entries(complete_path) == [".", ".."])
                        on_error "#{complete_path} is an empty directory"
                     else
                        # Test that directory matches DSSR naming convnetions
                        if not regex_unit.match(content)
                           on_error "#{content} does not match departmental naming convention of 9 digits"
                        else
                           # Entry passes all tests
                           FileUtils.mv File.join(finalization_dir, content), File.join(IN_PROCESS_DIR, content)
                           @unit_id = content.to_s.sub(/^0+/, '')
                           @messagable_id = @unit_id

                           on_success "Directory #{content} begins the finalization workflow."
                           QaUnitData.exec_now( { :unit_id => @unit_id })
                        end
                     end
                  end
               end
            end
         end
      end
   end
end
