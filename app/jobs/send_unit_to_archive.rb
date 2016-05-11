class SendUnitToArchive < BaseJob

   require 'find'
   require 'digest/md5'
   require 'pathname'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)

      raise "Parameter 'source_dir' is required" if message[:source_dir].blank?
      raise "Parameter 'internal_dir' is required" if message[:internal_dir].nil?
      source_dir = message[:source_dir]
      internal_dir = message[:internal_dir]

      # The next fork is whether the messages are coming from the start_manual processor or the regular finalization workflow
      # First, messages coming from the automated workflow
      if source_dir == "#{IN_PROCESS_DIR}"
         raise "Parameter 'unit' is required" if message[:unit].blank?
         unit = message[:unit]
         unit_dir = "%09d" % unit.id
      else
         # Second, messages coming from the start_manual processor
         raise "Parameter 'unit_dir' is required" if message[:unit_dir].blank?
         unit_dir = message[:unit_dir]
         unit = nil

         if internal_dir
            raise "Parameter 'unit' is required" if message[:unit].blank?
            unit = message[:unit]
         end
      end

      # Create array to hold all created directories so they can be removed after the process is complete
      created_dirs = Array.new
      error_count = 0

      Dir.chdir(source_dir)

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
                  # Introduce logic here to move the entire unit directory to REVIEW_DIR, or 50_fail_checksum
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
         # If message originated from the finalization automation workflow,
         # send a message to continue the unit (which has no deliverables) on the automated workflow.
         if source_dir == "#{IN_PROCESS_DIR}"
            on_success "The directory #{unit_dir} has been successfully archived."
            UpdateUnitDateArchived.exec_now({ :unit => unit, :source_dir => source_dir }, self)
         else
            if internal_dir
               # Unit is managed by TrackSys, more data must be updated.
               on_success "The directory #{unit_dir} has been archived and may be deleted."
               UpdateUnitDateArchived.exec_now({ :unit => unit, :source_dir => source_dir }, self)
            else
               # Non TrackSys data, no more information can be added to the tracking system and the item is ready for deletion.
               on_success "The directory #{unit_dir} has been archived and will now be moved to the #{DELETE_DIR_FROM_STORNEXT}."
               MoveCompletedDirectoryToDeleteDirectory.exec_now({ :source_dir => source_dir, :unit_dir => unit_dir}, self)
            end
         end
      else
         on_error "There were errors with the archiving process"
      end
   end
end
