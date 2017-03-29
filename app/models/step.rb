class Step < ActiveRecord::Base
   enum step_type: [:start, :end, :error, :normal]
   enum owner_type: [:any_owner, :prior_owner, :unique_owner, :original_owner, :supervisor_owner]

   validates :name, :presence => true

   belongs_to :workflow
   belongs_to :next_step, class_name: "Step"
   belongs_to :fail_step, class_name: "Step"

   # Perform end of step validation and automation
   #
   def finish( project )
      # determine if files should automatically be moved
      if self.manual
         begin
            # ensure presence of finish dir and files
            validate_manually_moved_files( project )
            return true
         rescue Exception => e
            Rails.logger.error("validate manually moved files FAILED #{e.to_s}")
            prob = Problem.find_by(name: "Filesystem")
            note = "<p>Files are missing from the finish directory. "
            note << "When the problem has been resolved, click finish again.</p>"
            note << "<p><b>Error details:</b> #{e.to_s}</p>"
            Note.create(staff_member: project.owner, project: project, note_type: :problem, note: note, problem: prob )
            project.active_assignment.update(status: :error )
            return false
         end
      end

      # make sure no illegal files are present in the starting directory
      Rails.logger.info "Validate start files for project #{project.id}, step #{project.current_step.id}"
      return false if !validate_start_files(project)

      begin
         # If a different finish dir is specified, move the files there
         if self.start_dir != self.finish_dir
            move_files( project )
         end
      rescue Exception => e
         Rails.logger.error("Move files FAILED #{e.to_s}")
         # Any problems moving files around will set the assignment as ERROR and leave it
         # uncompleted. A note detailing the error will be generated. At this point, the current
         # user can try again, or manually fix the directories and finish the step again.
         prob = Problem.find_by(name: "Filesystem")
         note = "<p>An error occurred moving files after step completion. Not all files have been moved. "
         note << "Please check and manually move each file. When the problem has been resolved, click finish again.</p>"
         note << "<p><b>Error details:</b> #{e.to_s}</p>"
         Note.create(staff_member: project.owner, project: project, note_type: :problem, note: note, problem: prob )
         project.active_assignment.update(status: :error )
         return false
      end
      return true
   end

   private
   def validate_start_files(project)
      # Error steps are all manual and cannot be generically validated
      # Just return true if this is an error step
      return true if self.error?

      unit_dir = "%09d" % project.unit.id
      start_dir =  File.join("#{PRODUCTION_MOUNT}", self.start_dir, unit_dir)

      # if start dir doesnt exist, assume it has been manually moved.
      return true if !Dir.exists?(start_dir)

      if Dir[File.join(start_dir, '**', '*.tif')].count { |file| File.file?(file) } == 0
         prob = Problem.find_by(name: "Filesystem")
         note = "<p>No image files found in starting directory #{start_dir}.</p>"
         Note.create(staff_member: project.owner, project: project, note_type: :problem, note: note, problem: prob )
         project.active_assignment.update(status: :error )
         return false
      end

      #  *.mpcatalog_* can be left over if the project was not saved. If any are
      # found, fail the step and prompt user to save changes and clean up
      if Dir[File.join(start_dir, '**', '*.mpcatalog_*')].count { |file| File.file?(file) } > 0
         prob = Problem.find_by(name: "Filesystem")
         note = "<p>Found *.mpcatalog_* files in #{start_dir}. "
         note << "Please ensure that you have no unsaved changes and delete these files.</p>"
         Note.create(staff_member: project.owner, project: project, note_type: :problem, note: note, problem: prob )
         project.active_assignment.update(status: :error )
         return false
      end

      return true
   end

   private
   def validate_manually_moved_files(project)
      unit_dir = "%09d" % project.unit.id
      dest_dir =  File.join("#{PRODUCTION_MOUNT}", self.finish_dir, unit_dir)
      Rails.logger.info("Validate files present in #{dest_dir}")

      if !Dir.exists?(dest_dir)
         raise "Finish directory #{dest_dir} does not exist."
      end
      if Dir[File.join(dest_dir, '**', '*.tif')].count { |file| File.file?(file) } == 0
         raise "Missing image files."
      end
   end

   private
   def move_files( project )
      unit_dir = "%09d" % project.unit.id
      src_dir =  File.join("#{PRODUCTION_MOUNT}", self.start_dir, unit_dir)
      dest_dir =  File.join("#{PRODUCTION_MOUNT}", self.finish_dir, unit_dir)
      Rails.logger.info("Moving working files from #{src_dir} to #{dest_dir}")

      # Neither directory exists; nothing can be done. Raise an exception
      if !Dir.exists?(src_dir) && !Dir.exists?(dest_dir)
         raise "Neither source nor destination directory exist."
      end

      # Source is gone, but dest exists and has files. Assume the owner
      # manualy moved the files and bail early
      if !Dir.exists?(src_dir) && Dir.exists?(dest_dir) && Dir[File.join(dest_dir, '**', '*.tif')].count { |file| File.file?(file) } > 0
         Rails.logger.info("Destination directory #{src_dir} exists, and is populated. Assuming move done manually.")
         return
      end

      # create dest if it doesn't exist
      Dir.mkdir(dest_dir) if !Dir.exists?(dest_dir)
      File.chmod(0755, dest_dir)

      # See if there is an 'Output' or 'output' folder present in the source directory
      output_dir =  File.join(src_dir, "Output")
      output_exists = false
      if !Dir.exists? output_dir
         output_dir =  File.join(src_dir, "output")
         output_exists =  Dir.exists? output_dir
      else
         output_exists = true
      end

      # NOTES ON Output Folder and file moves:
      # The contents of the Output folder need to be moved to a new folder in
      # 40_first_QA/(unit subfolder). The processing of images and generating of
      # .tifs will also create a subfolder entitled CaptureOne in the Output folder.
      # This folder and its contents need to be deleted. If the entire Output folder is renamed
      # to its associated unit number and moved to 40_first_QA, then the system needs to create another
      # Output folder in 10_raw/(unit subfolder). That way if the student needs to reprocess images on
      # the server, the default location is still available to process and save the .tifs. All other
      # contents of the unit subfolder in 10_raw/(unit subfolder) should remain where they are in 10_raw.

      # Output found; treat it as source directory. Its contents
      # will be moved into dest dir and then it will be removed, leaving
      # the root source folder intact
      if output_exists
         Rails.logger.info("Output directory found. Moving it to final directory.")
         src_dir = output_dir

         # remove CaptureOne if it exists
         cap_dir =  File.join(src_dir, "CaptureOne")
         if Dir.exists? cap_dir
            Rails.logger.info("Removing CaptureOne directory from Output")
            FileUtils.rm_r cap_dir
         end
      end

      # Move all files over and remove src dir
      src_files = Dir["#{src_dir}/*.{tif,xml,mpcatalog}"]
      src_files.each do |src_file|
         # src_md5 = Digest::MD5.hexdigest(File.read(src_file) )
         dest_file = File.join("#{dest_dir}", File.basename(src_file) )
         FileUtils.mv( src_file, dest_file)
         File.chmod(0664, dest_file)
         # dest_md5 = Digest::MD5.hexdigest(File.read(dest_file) )
         # if dest_md5 != src_md5
         #    raise "MD5 hash failed for #{dest_file}"
         # end
      end

      # Src is now empty. Remove it.
      FileUtils.rm_r src_dir

      if output_exists
         # put back the original src/ouput folder
         # in case student needs to recreate scans later
         FileUtils.mkdir src_dir
      end
   end
end
