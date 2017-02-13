class Step < ActiveRecord::Base
   enum step_type: [:start, :end, :error, :normal]

   validates :name, :presence => true

   belongs_to :workflow
   belongs_to :next_step, class_name: "Step"
   belongs_to :fail_step, class_name: "Step"

   def move_files?
      return self.start_dir != self.finish_dir
   end

   def move_files( unit )
      unit_dir = "%09d" % unit.id
      src_dir =  File.join("#{PRODUCTION_MOUNT}", self.start_dir, unit_dir)
      dest_dir =  File.join("#{PRODUCTION_MOUNT}", self.finish_dir, unit_dir)
      Rails.logger.info("Moving working files from #{src_dir} to #{dest_dir}")

      if !Dir.exists?(src_dir) && if !Dir.exists?(dest_dir)
         raise "Neither source nor destination directory exists!"
      end

      if !Dir.exists?(src_dir) && Dir.exists?(dest_dir) && Dir[File.join(dest_dir, '**', '*.tif')].count { |file| File.file?(file) } > 0
         Rails.logger.info("Destiation directory #{src_dir} exists, and is populated. Assuming move done manually.")
         return
      end

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

      FileUtils.rm_r src_dir
   end
end
