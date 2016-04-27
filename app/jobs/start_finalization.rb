class StartFinalization < BaseJob
   require 'fileutils'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"StaffMember", :originator_id=>message[:user_id])
   end

   def do_workflow(message)

      raise "Parameter 'directory' is required" if message[:directory].blank?

      regex_unit = Regexp.new('(\d{9}$)')

      finalization_dir = message[:directory]

      # Check that the mounts are up and the directory that holds the files still exists.
      if not File.exist?(finalization_dir)
         on_error "Finalization directory '#{finalization_dir}' does not exist."
      else
         contents = Dir.entries(finalization_dir).delete_if {|x| x == "." or x == ".." or x == ".AppleDouble" }

         # Check that there is content in the finalization directory
         finalized_count = 0
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
                           # schedule a new job to finalize this unit. This lets each unit have its own job log
                           logger().info "Schedule finalization for #{content}"
                           finalized_count += 1
                           FinalizeUnit.exec( { user_id: message[:user_id], unit_dir: content, finalization_dir:  finalization_dir} )
                        end
                     end
                  end
               end
            end
            if finalized_count == 0
               on_failure "No items to finalize in #{finalization_dir}"
            else
               on_success "All units in finalization directory have begun finalization"
            end
         end
      end
   end
end
