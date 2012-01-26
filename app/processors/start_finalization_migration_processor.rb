class StartFinalizationMigrationProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010
  require 'fileutils'

  subscribes_to :start_finalization_migration, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :qa_unit_data
   
  def on_message(message)
    regex_unit = Regexp.new('(\d{9}$)')

    # Check that the mounts are up and the directory that holds the files still exists.
    if not File.exist?(FINALIZATION_DROPOFF_DIR_MIGRATION)
      on_failure "#{FINALIZATION_DROPOFF_DIR_MIGRATION} directory does not exist.  Check mounts to NetApps."
    else
      contents = Dir.entries(FINALIZATION_DROPOFF_DIR_MIGRATION).delete_if {|x| x == "." or x == ".."}
      
      # Check that there is content in the finalization directory
      if contents.empty?
        on_success "No items to finalize in #{FINALIZATION_DROPOFF_DIR_MIGRATION}"
      else
        contents.each { |content| 
          if not /DS_Store/ =~ content
            complete_path = File.join(FINALIZATION_DROPOFF_DIR_MIGRATION, content)
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
                  FileUtils.mv File.join(FINALIZATION_DROPOFF_DIR_MIGRATION, content), File.join(IN_PROCESS_DIR, content)
                  @unit_id = content.to_s.sub(/^0+/, '')
                  message = ActiveSupport::JSON.encode( { :unit_id => @unit_id })
                  publish :qa_unit_data, message
                  on_success "Directory #{content} begins the finalization workflow."
                end
              end          
            end
          end
        }
      end
    end
  end
end
