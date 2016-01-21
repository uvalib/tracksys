class StartFinalizationProduction < BaseJob
   require 'fileutils'

   def perform(message)
      regex_unit = Regexp.new('(\d{9}$)')

      @messagable_type = "Unit"
      set_workflow_type()

      # Check that the mounts are up and the directory that holds the files still exists.
      if not File.exist?(FINALIZATION_DROPOFF_DIR_PRODUCTION)
         on_failure "#{FINALIZATION_DROPOFF_DIR_PRODUCTION} directory does not exist.  Check mounts to NetApps."
      else
         contents = Dir.entries(FINALIZATION_DROPOFF_DIR_PRODUCTION).delete_if {|x| x == "." or x == ".." or x == ".AppleDouble" }

         # Check that there is content in the finalization directory
         if contents.empty?
            on_failure "No items to finalize in #{FINALIZATION_DROPOFF_DIR_PRODUCTION}"
         else
            contents.each do |content|
               if not /DS_Store/ =~ content and not content == ".AppleDouble"
                  complete_path = File.join(FINALIZATION_DROPOFF_DIR_PRODUCTION, content)
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
                           FileUtils.mv File.join(FINALIZATION_DROPOFF_DIR_PRODUCTION, content), File.join(IN_PROCESS_DIR, content)
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
