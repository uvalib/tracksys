class Step < ApplicationRecord
   enum step_type: [:start, :end, :error, :normal]
   enum owner_type: [:any_owner, :prior_owner, :unique_owner, :original_owner, :supervisor_owner]

   validates :name, :presence => true

   belongs_to :workflow
   belongs_to :next_step, class_name: "Step"
   belongs_to :fail_step, class_name: "Step"
   has_many :notes

   # Perform end of step validation and automation
   #
   def finish( project )
      # For manual steps, just validate the finish directory
      if self.manual
         dest_dir =  File.join("#{PRODUCTION_MOUNT}", self.finish_dir, project.unit.directory)
         return validate_finish_dir( project, dest_dir )
      end

      # Make sure no illegal/stopper files are present in the starting directory
      # NOTE: The validation will be skipped if no start directory is found. This
      # is needed to handle error recovery when a automatic move failed and the
      # user manually moved files to finsh dir befor finish clicked
      Rails.logger.info "Validate start files for project #{project.id}, step #{project.current_step.id}"
      return false if !validate_start_dir(project)

      # Automatically move files to destination directory?
      if self.start_dir != self.finish_dir
         return move_files( project )
      end

      Rails.logger.info("No automatic file move needed; step is complete")
      return true
   end

   private
   def step_failed(project, problem_name, msg)
      prob = Problem.find_by(label: problem_name)
      prob = Problem.find_by(label: "Other") if prob.nil? # default to Other if problem not found
      note = Note.create(staff_member: project.owner, project: project, note_type: :problem, note: msg, step: project.current_step )
      note.problems << prob
      project.active_assignment.update(status: :error )
   end

   private
   def validate_start_dir(project)
      # Error steps are all manual so start dir cannot be validated (it wont exist as the owner
      # wil have moved it to teh finish location prior to clicking finish)
      return true if self.error?

      # get the base start directory
      start_dir =  File.join("#{PRODUCTION_MOUNT}", self.start_dir, project.unit.directory)

      # In the first Scan step, there may be a CaptureOne session in progress. If this is
      # the case, there will be a Capture directory present that is filled with IIQ files.
      # Some students don't use a Capture directory. Instead they use Recto and Verso.
      if self.name == "Scan"
         capture_exists = false
         tgts = ["Capture", "Recto", "Verso", "Rectos", "Versos", "recto", "verso", "rectos", "versos"]
         tgts.each do |tgt_dir|
            capture_dir = File.join(start_dir, tgt_dir)
            if Dir.exists?(capture_dir)
               capture_exists = true
               return true if Dir[File.join(capture_dir, '*.IIQ')].count > 0
            end
         end

         # if we got here and a capture directory exists, it must not
         # include IIQ files. Fail the step
         if capture_exists
            step_failed(project, "Filesystem", "<p>No raw files found in Capture, Recto or Verso directories</p>")
            return false
         end
      end

      # In the Process step, a CaptureOne session may also exist. In this case, there will be an Output
      # directory present. Treat it as the start dir and validate.
      if self.name == "Process"
         output_dir =  File.join(start_dir, "Output")
         if Dir.exists? output_dir
            start_dir = output_dir
            if Dir[File.join(start_dir, '*.tif')].count == 0
               Rails.logger.info "Start directory is empty. Assuming content manually moved by a user."
            end
         end
      end

      # if start dir doesn't exist and a move is called for, assume it has been manually moved
      if !Dir.exists?(start_dir)
         if self.start_dir == self.finish_dir
            step_failed(project, "Filesystem", "<p>Start directory #{start_dir} does not exist</p>")
            return false
         else
            Rails.logger.info "Start directory does not exist. Assuming it was manually moved by a user"
            return true
         end
      end

      return validate_directory_content(project, start_dir)
   end

   private
   def validate_finish_dir(project, dest_dir)
      Rails.logger.info("Validate files present in finish directory: #{dest_dir}")

      if !Dir.exists?(dest_dir)
         Rails.logger.error("Finish directory #{dest_dir} does not exist")
         step_failed(project, "Filesystem", "<p>Finish directory #{dest_dir} does not exist</p>")
         return false
      end

      # if Output exists within destination, use it instead
      output_dir =  File.join(dest_dir, "Output")
      dest_dir = output_dir if Dir.exists? output_dir

      # Directory is present and has images; make sure content is all OK
      return validate_directory_content(project, dest_dir)
   end

   private
   def validate_directory_content(project, dir)
      # Make sure the names match the unit & highest number is the same as the count
      highest = -1
      cnt = 0
      unit_dir = project.unit.directory
      Dir[File.join(dir, '*.tif')].each do |f|
         name = File.basename f,".tif" # get name minus extention
         num = name.split("_")[1].to_i
         cnt += 1
         highest = num if num > highest
         if name.split("_")[0] != unit_dir
            step_failed(project, "Filename", "<p>Found incorrectly named image file #{f}.</p>")
            return false
         end
      end
      if cnt == 0
         step_failed(project, "Filesystem", "<p>No image files found in #{dir}</p>")
         return false
      end
      if highest != cnt
         step_failed(project, "Filename", "<p>Number of image files does not match highest image sequence number #{highest}.</p>")
         return false
      end

      # Make sure there is at most 1 mpcatalog file
      cnt = 0
      Dir[File.join(dir, '*.mpcatalog')].each do |f|
         cnt += 1
         if cnt > 1
            step_failed(project, "Metadata", "<p>Found more than one .mpcatalog file.</p>")
            return false
         end

         name = File.basename f,".mpcatalog"
         if name != unit_dir
            step_failed(project, "Filename", "<p>Found incorrectly named .mpcatalog file #{f}.</p>")
            return false
         end
      end

      # once NEXT step has a failure path (meaning it is a QA step),
      # fail current step if there is no mpcatalog
      next_step = project.current_step.next_step
      if cnt == 0 && !next_step.nil? && !next_step.fail_step.blank?
         step_failed(project, "Metadata", "<p>Missing #{unit_dir}.mpcatalog file</p>")
         return false
      end

      #  *.mpcatalog_* can be left over if the project was not saved. If any are
      # found, fail the step and prompt user to save changes and clean up
      if Dir[File.join(dir, '*.mpcatalog_*')].count { |file| File.file?(file) } > 0
         step_failed(project, "Unsaved", "<p>Found *.mpcatalog_* files in #{start_dir}. Please ensure that you have no unsaved changes and delete these files.</p>")
         return false
      end

      # On the final step, be sure there is an XML file present that
      # has a name matching the unit directory
      if self.end?
         Rails.logger.info("Final step validations; look for unit.xml file and ensure no unexpected files exist")
         if !File.exists? File.join(dir, "#{unit_dir}.xml")
            step_failed(project, "Metadata", "<p>Missing #{unit_dir}.xml</p>")
            return false
         end

         # Make sure only .tif, .xml and .mpcatalog files are present. Fail if others
         Dir[File.join(dir, '*')].each do |f|
            ext = File.extname f
            ext.downcase!
            if ext != ".xml" && ext != ".tif" && ext != ".mpcatalog"
               step_failed(project, "Filesystem", "<p>Unexpected file or directory #{f} found</p>")
               return false
            end
         end
      end

      return true
   end

   private
   # NOTES ON Output Folder and file moves:
   # The contents of the Output folder need to be moved to a new folder in
   # 40_first_QA/(unit subfolder). The processing of images and generating of
   # .tifs will also create a subfolder entitled CaptureOne in the Output folder.
   # This folder and its contents need to be deleted. If the entire Output folder is renamed
   # to its associated unit number and moved to 40_first_QA, then the system needs to create another
   # Output folder in 10_raw/(unit subfolder). That way if the student needs to reprocess images on
   # the server, the default location is still available to process and save the .tifs. All other
   # contents of the unit subfolder in 10_raw/(unit subfolder) should remain where they are in 10_raw.
   def move_files( project )
      src_dir =  File.join("#{PRODUCTION_MOUNT}", self.start_dir, project.unit.directory)
      dest_dir =  File.join("#{PRODUCTION_MOUNT}", self.finish_dir, project.unit.directory)

      Rails.logger.info("Moving working files from #{src_dir} to #{dest_dir}")

      # Both exist; something is wrong. Fail
      if Dir.exists?(src_dir) && Dir.exists?(dest_dir)
         Rails.logger.error("Both source dir #{src_dir} and destination dir #{dest_dir} exist")
         step_failed(project, "Filesystem", "<p>Both source dir #{src_dir} and destination dir #{dest_dir} exist</p>")
         return false
      end

      # Neither directory exists, this is generally a failure, but a special case exists.
      # Files may be 20_in_process if a prior finalization failed. Accept this.
      alt_dest_dir = File.join(IN_PROCESS_DIR,  project.unit.directory)
      if !Dir.exists?(src_dir) && !Dir.exists?(dest_dir)
         if self.end? && Dir.exists?(alt_dest_dir)
            Rails.logger.info "On finalization step with in_process unit files found in #{alt_dest_dir}"
            dest_dir = alt_dest_dir
         else
            Rails.logger.error("Neither source nor destination directories exist")
            step_failed(project, "Filesystem", "<p>Neither start nor finsh directory exists</p>")
            return false
         end
      end

      # Source is gone, but dest exists... Validate it
      if !Dir.exists?(src_dir) && Dir.exists?(dest_dir)
         Rails.logger.info("Destination directory #{dest_dir} exists, and is populated. Validating...")
         return validate_finish_dir(project, dest_dir)
      end

      # See if there is an 'Output' directory for special handling
      output_dir =  File.join(src_dir, "Output")
      has_output_dir = false

      # If Output exists, treat it as the source directory - Its contents
      # will be moved into dest dir and then it will be removed, leaving
      # the root source folder intact. See notes at top of this call for details.
      begin
         if Dir.exists? output_dir
            Rails.logger.info("Output directory found. Moving it to final directory.")
            src_dir = output_dir
            has_output_dir = true

            # remove CaptureOne if it exists
            cap_dir =  File.join(src_dir, "CaptureOne")
            if Dir.exists? cap_dir
               Rails.logger.info("Removing CaptureOne directory from Output")
               FileUtils.rm_rf cap_dir
            end
         end

         # Move the source directly to destination directory
         FileUtils.mv(src_dir, dest_dir)

         # put back the original src/Ouput folder in case student needs to recreate scans later
         if has_output_dir
            FileUtils.mkdir src_dir
            File.chmod(0775, src_dir)
         end

         # One last validation of final directory contents, then done
         return validate_finish_dir(project, dest_dir)
      rescue Exception => e
         Rails.logger.error("Move files FAILED #{e.to_s}")
         # Any problems moving files around will set the assignment as ERROR and leave it
         # uncompleted. A note detailing the error will be generated. At this point, the current
         # user can try again, or manually fix the directories and finish the step again.
         note = "<p>An error occurred moving files after step completion. Not all files have been moved. "
         note << "Please check and manually move each file. When the problem has been resolved, click finish again.</p>"
         note << "<p><b>Error details:</b> #{e.to_s}</p>"
         step_failed(project, "Filesystem", note)
         return false
      end
   end
end
