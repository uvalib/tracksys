# == Schema Information
#
# Table name: steps
#
#  id           :integer          not null, primary key
#  step_type    :integer          default("normal")
#  name         :string(255)
#  description  :text(65535)
#  workflow_id  :integer
#  next_step_id :integer
#  fail_step_id :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  owner_type   :integer          default("any_owner")
#

class Step < ApplicationRecord
   enum step_type: [:start, :end, :error, :normal]
   enum owner_type: [:any_owner, :prior_owner, :unique_owner, :original_owner, :supervisor_owner]

   validates :name, :presence => true

   belongs_to :workflow
   belongs_to :next_step, class_name: "Step", optional: true
   belongs_to :fail_step, class_name: "Step", optional: true
   has_many :notes

   # Presence of a fail_step means this is a QA step
   def is_qa?
      return !self.fail_step.nil?
   end

   # Perform end of step validation and automation
   #
   def finish( project )
      if self.workflow.name == "Manuscript" && project.container_type.nil?
         step_failed(project, "Other", "<p>This project is missing the required Container Type setting.</p>")
         return false
      end

      # Make sure  directory is clean and in proper structure
      tgt_dir = File.join(Settings.image_qa_dir, project.unit.directory)
      if self.name == "Scan" || self.name == "Process"
         tgt_dir = File.join(Settings.production_mount, "scan", "10_raw", project.unit.directory)
      end
      return false if !validate_directory(project, tgt_dir)

      # Files get moved in two places; after Process and Finalization
      if self.name == "Process"
         src_dir =  File.join(Settings.production_mount, "scan", "10_raw", project.unit.directory)
         tgt_dir = File.join(Settings.image_qa_dir, project.unit.directory)
         return move_files( project, src_dir, tgt_dir )
      end
      if self.name == "Finalize"
         src_dir = File.join(Settings.image_qa_dir, project.unit.directory)
         tgt_dir =  File.join(Settings.production_mount, "finalization", project.unit.directory)
         return move_files( project, src_dir, tgt_dir )
      end

      return true
   end

   private
   def validate_directory(project, tgt_dir)
      Rails.logger.info "Validate directory #{tgt_dir} for project #{project.id} step #{self.name}"

      # Scan and Process and Error steps have no checks other than directory existance
      if self.name == "Scan" || self.name == "Process" || self.error?
         if !Dir.exists?(tgt_dir)
            Rails.logger.error "Scan directory #{tgt_dir} does not exist"
            step_failed(project, "Filesystem", "<p>Directory #{tgt_dir} does not exist</p>")
            return false
         end
         return true
      end

      # all checks occur on the unit directory in dpg_imaging
      if !Dir.exists?(tgt_dir)
         Rails.logger.error "Directory #{tgt_dir} does not exist"
         step_failed(project, "Filesystem", "<p>Directory #{tgt_dir} does not exist</p>")
         return false
      end

      # make sure only .tif and notes.txt are present
      return false if !validate_content(project, tgt_dir)

      # enforce naming/numbering
      return false if !validate_tif_sequence(project, tgt_dir)

      if self.workflow.name == "Manuscript"
         # for manuscript enforce box/folder structure
         return false if !validate_structure(project, tgt_dir)
      end
      return true
   end

   private
   def validate_tif_sequence(project, base_dir)
      Rails.logger.info "Validate .tif count and sequence of #{base_dir}"
      # get .tif search path.. Note the /**/ in tif path to make the search include subdirs for manuscripts
      tif_path = File.join(base_dir, '/**/*.tif')

      highest = -1
      cnt = 0
      unit_dir = project.unit.directory
      Dir[ tif_path ].sort.each do |f|
         name = File.basename f,".tif" # get name minus extention
         if (name =~ /\d{9}_\d{4}/).nil?
            step_failed(project, "Filename", "<p>Found incorrectly named image file #{f}.</p>")
            return false
         end
         num = name.split("_")[1].to_i
         cnt += 1
         highest = num if num > highest
         if name.split("_")[0] != unit_dir
            step_failed(project, "Filename", "<p>Found incorrectly named image file #{f}.</p>")
            return false
         end

         # once finish is clicked on a unit with .tif images, all the images must have at least title metadata
         cmd = "exiftool -json -iptc:headline #{f}"
         exif_out = `#{cmd}`
         if exif_out.blank?
            step_failed(project, "Metadata", "<p>Unable to extract metadata from #{f}.</p>")
            return false
         end
         md = JSON.parse(exif_out).first
         if md['Headline'].blank?
            step_failed(project, "Metadata", "<p>Missing Tile metadata in #{f}.</p>")
            return false
         end

      end
      if cnt == 0
         step_failed(project, "Filesystem", "<p>No image files found in #{base_dir}</p>")
         return false
      end
      if highest != cnt
         step_failed(project, "Filename", "<p>Number of image files does not match highest image sequence number #{highest}.</p>")
         return false
      end
      return true
   end

   private
   def validate_structure(project, dir)
      # All mnuscripts have a top level directory with any name. If ContainerType is
      # set to has_folders=true, this much contain folders only. tif images reside there,
      # If not, the top-level directory containes the tif images
      container_type = project.container_type
      found_container_dir = false
      found_folders = false
      Dir.glob("#{dir}/**/*").sort.each do |entry|
         if File.directory? (entry)

            # entry is the full path. Strip off the base dir, leaving just the subdirectories and files
            subs = entry[dir.length+1..-1]

            # Split on path seperator. The size is depth of subfolders present
            depth = subs.split("/").count
            if depth > 2
               step_failed(project, "Filesystem", "<p>Too many subdirectories: #{subs}</p>")
               return false
            end

            if depth == 2
               # folders within a top-level container
               if container_type.has_folders == false
                  step_failed(project, "Filesystem", "<p>Folder directories not allowed in '#{container_type.name}' containers</p>")
                  return false
               end
               found_folders = true
            end

            if depth == 1
               # Top-level container directory; there can only be one
               if found_container_dir == true
                  step_failed(project, "Filesystem", "<p>There can only be one box directory</p>")
                  return false
               end
               found_container_dir = true
            end
         else
            # This is a file. Count slashes to figure out where in the
            # directory tree this file resides. One slash is the box level.
            # Validate based on folders flag in the container_type model
            subs = File.dirname(entry)[dir.length+1..-1]
            next if subs.blank?
            if subs.split("/").count == 1 && container_type.has_folders
               step_failed(project, "Filesystem", "<p>Files found in box directory: #{subs}</p>")
               return false
            end
         end
      end

      # Validate presence of folders based on container_type
      if found_folders == false && container_type.has_folders == true
         step_failed(project, "Filesystem", "<p>No folder directories found</p>")
         return false
      end
      return true
   end

   private
   def validate_content(project, dir)
      # Make sure only .tif and notes.txt are present
      Dir[File.join(dir, '/**/*')].sort.each do |f|
         next if File.directory? f

         if self.workflow.name == "Manuscript"
            if File.basename(f).downcase == "notes.txt"
               Rails.logger.info("Found location notes file for manifest project. Keeping it for ingest later.")
               next
            end
         end

         ext = File.extname f
         ext.downcase!

         if ext == ".noindex"
            Rails.logger.info("Deleting tmp file #{f}")
            FileUtils.rm(f)
            next
         end

         if ext != ".tif"
            step_failed(project, "Filesystem", "<p>Unexpected file or directory #{f} found</p>")
            return false
         end
      end
      return true
   end

   private
   def move_files( project, src_dir, dest_dir )
      Rails.logger.info("Step #{self.name}: moving working files from #{src_dir} to #{dest_dir}")
      has_delete_me = Dir.glob("#{src_dir}/**/DELETE.ME").length > 0

      # Both exist without DELETE.ME; something is wrong. Fail
      if Dir.exists?(src_dir) && Dir.exists?(dest_dir) && has_delete_me == false
         Rails.logger.error("Both source dir #{src_dir} and destination dir #{dest_dir} exist")
         step_failed(project, "Filesystem", "<p>Both source dir #{src_dir} and destination dir #{dest_dir} exist</p>")
         return false
      end

      # Neither directory exists, this is generally a failure, but a special case exists.
      # Files may be 20_in_process if a prior finalization failed. Accept this.
      if !Dir.exists?(src_dir) && !Dir.exists?(dest_dir)
         alt_dest_dir = Finder.finalization_dir(project.unit, :in_process)
         if self.end? && Dir.exists?(alt_dest_dir)
            Rails.logger.info "On finalization step with in_process unit files found in #{alt_dest_dir}"
            return true
         else
            Rails.logger.error("Neither source nor destination directories exist")
            step_failed(project, "Filesystem", "<p>Neither start nor finsh directory exists</p>")
            return false
         end
      end

      # Source is gone or has the DELETE.ME file, but dest exists. No move needed
      if (!Dir.exists?(src_dir) || has_delete_me ) && Dir.exists?(dest_dir)
         Rails.logger.info("Source is missing and destination directory #{dest_dir} already exists")
         return true
      end

      # See if there is an 'Output' directory for special handling. This is the directory where CaptureOne
      # places the generated .tif files. Treat it as the source location if it is present
      output_dir =  File.join(src_dir, "Output")
      if Dir.exists? output_dir
         Rails.logger.info("Output directory found. Moving it to final directory.")
         src_dir = output_dir
      end

      # Do the move and sanity check on results. If .AppleDouble is present, move individual files and drop a DELETE.ME
      if Dir.glob("#{src_dir}/**/.AppleDouble").length > 0
         Rails.logger.info("Source #{src_dir} contains an .AppleDouble file and could not be moved")
         msg = "Directory #{src_dir} contains .AppleDouble files and could not be removed. Manual cleanup required."
         Note.create(staff_member: project.owner, project: project, note_type: :comment, note: msg, step: project.current_step )

         Dir.glob("#{src_dir}/**/*.tif").sort.each do |entry|
            tgt_file = entry.gsub(src_dir, dest_dir)
            new_dir = File.dirname(tgt_file)
            if !Dir.exist? new_dir
               Rails.logger.info("Create dest_dir #{new_dir}")
               FileUtils.mkdir_p(new_dir)
               FileUtils.chmod(0775, new_dir)
            end
            Rails.logger.info("Move #{entry} to #{tgt_file}")
            FileUtils.mv(entry, tgt_file)
         end

         del =  File.join(src_dir, "DELETE.ME")
         File.open(del, "w") { |file| file.write "moved to #{dest_dir}\n" }
      else
         FileUtils.mv(src_dir, dest_dir, force: true)
      end

      if !validate_directory(project, dest_dir)
         Rails.logger.error("Destination #{src_dir} did not validate")
         step_failed(project, "Filesystem", "<p>Errprs have occurred moving files to #{dest_dir}</p>")
         return false
      end

      Rails.logger.info("Files successfully moved to #{dest_dir}")
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
end
