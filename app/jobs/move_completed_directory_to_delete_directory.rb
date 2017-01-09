class MoveCompletedDirectoryToDeleteDirectory < BaseJob
   require 'fileutils'

   def do_workflow(message)

      unit_id = message[:unit_id]
      source_dir = message[:source_dir]

      if message[:unit_dir]
         unit_dir = message[:unit_dir]
      else
         unit_dir = "%09d" % unit_id
      end

      # If source_dir matches a stornext manual upload dir, move to DELETE_DIR_FROM_STORNEXT
      if /#{MANUAL_UPLOAD_TO_ARCHIVE_DIR_PRODUCTION}|#{MANUAL_UPLOAD_TO_ARCHIVE_DIR_MIGRATION}/ =~ source_dir
         FileUtils.mv File.join(source_dir, unit_dir), File.join(DELETE_DIR_FROM_STORNEXT, unit_dir)
         on_success "All files associated with #{unit_dir} has been moved to #{DELETE_DIR_FROM_STORNEXT}."

      # If source_dir matches a stornext manual upload dir from the batch migration mount (i.e. /lib_content37), move to BATCH_MIGRATION_DELETE_DIR_FROM_STORNEX
      elsif /#{MANUAL_UPLOAD_TO_ARCHIVE_DIR_BATCH_MIGRATION}/ =~ source_dir
         FileUtils.mv File.join(source_dir, unit_dir), File.join(BATCH_MIGRATION_DELETE_DIR_FROM_STORNEXT, unit_dir)
         on_success "All files associated with #{unit_dir} has been moved to #{BATCH_MIGRATION_DELETE_DIR_FROM_STORNEXT}."

      # Unit update?
      elsif /unit_update/ =~ source_dir
         del_dir = File.join(DELETE_DIR, "from_update", unit_id.to_s)
         if Dir.exists? del_dir
            del_dir = del_dir.chomp("/")    # remove the trailing slash if present
            del_dir << Time.now.to_i.to_s   # add a timestamp
         end
         FileUtils.mv source_dir, del_dir
         on_success "All update files for unit #{unit_id} have been moved to #{del_dir}."

      # If source_dir matches the finalization in process dir, move to DELETE_DIR_FROM_FINALIZATION and look for items in /digiserv-production/scan
      elsif /#{IN_PROCESS_DIR}/ =~ source_dir
         FileUtils.mv File.join(source_dir, unit_dir), File.join(DELETE_DIR_FROM_FINALIZATION, unit_dir)
         on_success "All files associated with #{unit_dir} has been moved to #{DELETE_DIR_FROM_FINALIZATION}."

         # Once the files are moved from IN_PROCESS_DIR, search /digiserv-production/scan for legacy files and move them to DELETE_DIR_FROM_SCAN
         # check not only for directories with the full unit_id (i.e. 9 digits) but also just the unit digits to allow for directories that students often rename rescan6543.
         # If found, rename them unit_id + _[source_dir] (i.e. 000006543_40_first_QA]
         # All units that undergo the logic below would have a unit_id value

         # ToDo: If /ARCH|AVRN/ =~ unit_id

         PRODUCTION_SCAN_SUBDIRECTORIES.each do |dir|
            if  Dir.exists? (  File.join("#{PRODUCTION_SCAN_DIR}", "#{dir}" )  )
               puts dir
               contents = Dir.entries(File.join("#{PRODUCTION_SCAN_DIR}", "#{dir}")).delete_if {|x| x == "." or x == ".." or x == ".DS_Store" or /\._/ =~ x or x == ".AppleDouble" }
               contents.each do |content|
                  if /#{unit_id}/ =~ content
                     # Ignore potential matches with Fine Arts content
                     if not ( /ARCH|AVRN/ =~ content )
                        FileUtils.mv File.join("#{PRODUCTION_SCAN_DIR}", "#{dir}", "#{content}"), File.join(DELETE_DIR_FROM_SCAN, "#{content}_from_#{dir}")
                        on_success "Directory #{content} has been moved from #{PRODUCTION_SCAN_DIR}/#{dir} to #{DELETE_DIR_FROM_SCAN}."
                     end

                     # If both content and unit_id match /ARCH|AVRN/, then move the content directory to the DELETE_FROM_SCAN_DIR
                     if /ARCH|AVRN/ =~ content and /ARCH|AVRN/ =~ unit_id
                        FileUtils.mv File.join("#{PRODUCTION_SCAN_DIR}", "#{dir}", "#{content}"), File.join(DELETE_DIR_FROM_SCAN, "#{content}_from_#{dir}")
                        on_success "Directory #{content} has been moved from #{PRODUCTION_SCAN_DIR}/#{dir} to #{DELETE_DIR_FROM_SCAN}."
                     end
                  end
               end
            end
         end
      else
         on_error "There is an error in the message sent to move_completed_directory_to_delete_directory.  The source_dir variable is set to an unknown value: #{source_dir}."
      end
   end
end
