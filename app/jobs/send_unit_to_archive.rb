class SendUnitToArchive < BaseJob

   require 'find'
   require 'digest/md5'
   require 'pathname'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)

      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      unit = Unit.find(message[:unit_id])
      unit_dir = "%09d" % unit.id

      # Create array to hold all created directories so they can be removed after the process is complete
      created_dirs = Array.new
      error_count = 0

      Dir.chdir(IN_PROCESS_DIR)

      Find.find(unit_dir) do |f|
         case
         when File.file?(f)
            # Get pertinent information for creating dirs in REVIEW and DELETE dirs
            p = Pathname.new(f)
            parent = p.parent.to_s
            basename = p.basename.to_s

            # Ignore files that begin with .
            if /^\./ =~ basename
            else
               FileUtils.copy(f, File.join(ARCHIVE_DIR, parent, basename))
               FileUtils.chmod(0664, File.join(ARCHIVE_DIR, parent, basename))
               # Calculate information for checksums

               # Get source MD5
               source_md5 = Digest::MD5.new
               File.open(f, 'r') do |file|
                  source_md5.update(file.read(16384)) until file.eof
               end

               # Get copy MD5
               copy_md5 = Digest::MD5.new
               File.open(File.join(ARCHIVE_DIR, parent, basename), 'r') do |file|
                  copy_md5.update(file.read(16384)) until file.eof
               end

               # Run checksum tests
               if copy_md5.hexdigest != source_md5.hexdigest
                  on_failure("** Warning ** - File #{f} has failed checksum test")
                  error_count += 1
               else
                  # While we've got the md5 available, add to MasterFile object.  Record the md5 is a new feature
                  # added in Summer 2012.
                  #
                  # TODO: We need a way to discriminate between those files being archived that are managed directly by
                  # Tracksys (i.e. those that are "MasterFile" objects) and those that are not (i.e .ivc files).  The following
                  # rescue condition is a hack but is easiest to institute at the time.
                  mf = MasterFile.find_by(filename: basename)
                  if !mf.nil?
                     mf.update_attributes(:md5 => source_md5.hexdigest)
                  end
               end
            end
         when File.directory?(f)
            FileUtils.makedirs(File.join(ARCHIVE_DIR, f))
            FileUtils.chmod(0775, File.join(ARCHIVE_DIR, f))
            created_dirs << f
         else
            on_failure("Unknown file #{f} in #{parent}/#{basename}")
         end
      end

      if error_count == 0
         logger.info "The directory #{unit_dir} has been successfully archived."
         unit.update(date_archived: Time.now)
         unit.master_files.each do |mf|
            mf.update(date_archived: Time.now)
         end
         logger.info "Date Archived set to #{unit.date_archived} for for unit #{unit.id}"

         CheckOrderDateArchivingComplete.exec_now({ :order_id => unit.order_id }, self)

         # Now that all archiving work for the unit is done, it (and any subsidary files) must be moved to the ready_to_delete directory
         MoveCompletedDirectoryToDeleteDirectory.exec_now({ :unit_id => unit.id, :source_dir => IN_PROCESS_DIR}, self)
      else
         on_error "There were errors with the archiving process"
      end
   end
end
