class Step < ActiveRecord::Base
   enum step_type: [:start, :end, :error, :normal]
   enum owner_type: [:any_owner, :prior_owner, :unique_owner, :original_owner, :supervisor_owner]

   validates :name, :presence => true

   belongs_to :workflow
   belongs_to :next_step, class_name: "Step"
   belongs_to :fail_step, class_name: "Step"

   def validate_manually_moved_files(unit)
      unit_dir = "%09d" % unit.id
      dest_dir =  File.join("#{PRODUCTION_MOUNT}", self.finish_dir, unit_dir)
      Rails.logger.info("Validate files present in #{dest_dir}")

      # First possible problem; dest dir is not present
      if !Dir.exists?(dest_dir)
         raise "Destination directory #{dest_dir} does not exist!"
      end

      if Dir[File.join(dest_dir, '**', '*.mpcatalog')].count { |file| File.file?(file) } == 0
         raise "Missing .mpcatalog file"
      end

      if Dir[File.join(dest_dir, '**', '*.xml')].count { |file| File.file?(file) } == 0
         raise "Missing .xml metadata file"
      end

      if Dir[File.join(dest_dir, '**', '*.tif')].count { |file| File.file?(file) } == 0
         raise "Missing image files"
      end
   end

   def move_files?
      return self.start_dir != self.finish_dir
   end

   def move_files( unit )
      unit_dir = "%09d" % unit.id
      src_dir =  File.join("#{PRODUCTION_MOUNT}", self.start_dir, unit_dir)
      dest_dir =  File.join("#{PRODUCTION_MOUNT}", self.finish_dir, unit_dir)
      Rails.logger.info("Moving working files from #{src_dir} to #{dest_dir}")

      # Neither directory exists; nothing can be done. Raise an exception
      if !Dir.exists?(src_dir) && !Dir.exists?(dest_dir)
         raise "Neither source nor destination directory exist!"
      end

      # Source is gone, but dest exists and has files. Assume the owner
      # manualy moved the files and bail early
      if !Dir.exists?(src_dir) && Dir.exists?(dest_dir) && Dir[File.join(dest_dir, '**', '*.tif')].count { |file| File.file?(file) } > 0
         Rails.logger.info("Destiation directory #{src_dir} exists, and is populated. Assuming move done manually.")
         return
      end

      # create dest if it doesn't exist, and move each file over. Check MD5.
      Dir.mkdir(dest_dir) if !Dir.exists?(dest_dir)

      src_files = Dir["#{src_dir}/*.{tif,xml,mpcatalog}"]
      src_files.each do |src_file|
         src_md5 = Digest::MD5.hexdigest(File.read(src_file) )
         dest_file = File.join("#{dest_dir}", File.basename(src_file) )
         FileUtils.mv( src_file, dest_file)
         dest_md5 = Digest::MD5.hexdigest(File.read(dest_file) )
         if dest_md5 != src_md5
            raise "MD5 hash failed for #{dest_file}"
         end
      end

      # Src is now empty. Remove it.
      FileUtils.rm_r src_dir
   end
end
