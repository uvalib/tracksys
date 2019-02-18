class MoveCompletedDirectoryToDeleteDirectory < BaseJob
   require 'fileutils'

   def do_workflow(message)

      unit_id = message[:unit_id]
      unit = Unit.find(unit_id)
      source_dir = message[:source_dir]

      if message[:unit_dir]
         unit_dir = message[:unit_dir]
      else
         unit_dir = "%09d" % unit_id
      end

      if !Dir.exists? source_dir
         logger.info "Source directory #{source_dir} has already been removed"
         return
      end

      # Unit update or xml upload?
      if /unit_update/ =~ source_dir || /xml_metadata/ =~ source_dir
         del_dir = Finder.finalization_dir(unit, :delete_from_update)
         if Dir.exists? del_dir
            del_dir = del_dir.chomp("/")        # remove the trailing slash if present
            del_dir << "_#{Time.now.to_i.to_s}" # add a timestamp
         end
         FileUtils.mv source_dir, del_dir
         logger.info "All update files for unit #{unit_id} have been moved to #{del_dir}."

      # If source_dir matches the finalization in process dir, move to delet and look for items in /scan
      elsif /20_in_process/ =~ source_dir
         del_dir = Finder.finalization_dir(unit, :delete_from_finalization)
         FileUtils.mv source_dir, del_dir
         logger.info "All files associated with #{unit_dir} has been moved to #{del_dir}."

         # Once the files are moved from the in process directory, dump all scan directories too
         # This call returns directories like: /MOUNT/scan/10_raw
         Finder.scan_dirs(unit).each do |scan_dir|
            if  Dir.exists? scan_dir
               contents = Dir.entries(scan_dir).delete_if {|x| x == "." or x == ".." or x == ".DS_Store" or /\._/ =~ x or x == ".AppleDouble" }
               contents.each do |content|
                  if /#{unit.id}/ =~ content
                     p = Pathname.new(scan_dir)
                     del_dir = Finder.ready_to_delete_from_scan(unit, p.basename.to_s)
                     src_dir = File.join(scan_dir, content)
                     FileUtils.mv(src_dir, del_dir)
                     logger.info "All files moved from #{src_dir} to #{del_dir}"
                  end
               end
            end
         end
      else
         fatal_error "There is an error in the message sent to move_completed_directory_to_delete_directory.  The source_dir variable is set to an unknown value: #{source_dir}."
      end
   end
end
