module Bagit
   # Bag  class wraps functionality for creating a bag, adding files/tagfiles,
   # generating checksums into a single place
   class Bag 
      attr_reader :bag_dir
      attr_reader :tag_files
      attr_reader :files 
      attr_reader :bag_name

      # Create a new bag from a config hash. Accepted has params:
      #   bag (required), title (required), pid, storage, access
      # Note: Bag name follows the pattern <institution.edu>.bag_name[.b###.of###].tar.
      def initialize( cfg, logger = Rails.logger )
         name = cfg[:bag]
         title = cfg[:title]
         pid = cfg[:pid]
         storage = cfg[:storage]
         storage = "Standard" if storage.blank?
         access = cfg[:access]
         access = "Consortia" if access.blank?
         
         # Make sure cfg is valid 
         raise "Bag name required" if name.blank?
         raise "Title name required" if title.blank?
         valid_access =  ["Consortia", "Restricted", "Institution"]
         raise "Invalid access '#{access}'" if !valid_access.include? access
         valid_store =  ["Standard", "Glacier-OH", "Glacier-OR", "Glacier-VA"]
         raise "Invalid storage '#{storage}'" if !valid_store.include? storage
         @bag_name = "virginia.edu.#{name}"
         @logger = logger
         @logger.info("Create bag #{@bag_name}")

         # Purge old bag and create new content directory
         @bag_dir = File.join(Rails.root, "tmp", "bags", @bag_name)
         if Dir.exist? @bag_dir 
            FileUtils.rm_rf(@bag_dir)
         end
         FileUtils.mkdir_p( @bag_dir )

         # Make the data dir...
         data_dir = File.join(@bag_dir, "data")
         FileUtils.mkdir_p( data_dir )

         # add the aptrust-info.txt, bag-info.txt, bagit.txt. bagit.txt is not a tag file 
         bagit = "BagIt-Version: 0.97\nTag-File-Character-Encoding: UTF-8"
         File.open(File.join(@bag_dir, "bagit.txt"), "w") { |file| file.write bagit }

         apt_file = File.join(@bag_dir, "aptrust-info.txt")
         apt = "Title: #{title}\nDescription: \nAccess: #{access}\nStorage-Option: #{storage}"
         File.open(apt_file, "w") { |file| file.write apt }
         @tag_files = ["aptrust-info.txt"]

         info_file = File.join(@bag_dir, "bag-info.txt")
         info = "Source-Organization: virginia.edu\nBagging-Date: #{DateTime.now.iso8601}\nBag-Count: 1 of 1\n"
         info << "Internal-Sender-Description: \nInternal-Sender-Identifier: #{pid}\nBag-Group-Identifier: "
         File.open(info_file, "w") { |file| file.write info }
         @tag_files << "bag-info.txt"
      end

      # Add the file found at src_path to the bag and name it with the filename param 
      # Omit src path and provide a block st stream in data from something other than a file 
      # on the filesystem
      def add_file(filename, full_src_path=nil) 
         @logger.info("Add #{filename} to bag #{@bag_name}")
         data_dir = File.join(@bag_dir, "data")
         dest_file = File.join(data_dir, filename)
         if full_src_path.nil?
            File.open(dest_file, 'w') { |io| yield io }
         else
            raise "#{full_src_path} not found" if !File.exist? full_src_path
            FileUtils.cp full_src_path, dest_file
         end

         @files = [] if @files.nil?
         @files << File.join("data", filename)
      end

      # Generate MD5 and SHA256 manifests for all files and tag files. Any prior 
      # manifests will be overwritten
      def generate_manifests 
         @logger.info("Generate manifests for bag #{@bag_name}")
         FileUtils.rm_f( Dir.glob(File.join(@bag_dir, "manifest*")))
         FileUtils.rm_f( Dir.glob(File.join(@bag_dir, "tagmanifest*")))

         @files.each do |f|
            src = File.join(@bag_dir, f)
            write_md5(File.join(@bag_dir, "manifest-md5.txt"), src, f)
            write_sha256(File.join(@bag_dir, "manifest-sha256.txt"), src, f)
         end 

         @tag_files.each do |f|
            src = File.join(@bag_dir, f)
            write_md5(File.join(@bag_dir, "tagmanifest-md5.txt"), src, f)
            write_sha256(File.join(@bag_dir, "tagmanifest-sha256.txt"), src, f)
         end 
      end

      # Tar bag file for submission and return path to bag
      def tar 
         @logger.info("Tar bag #{@bag_name}")
         bag_base = File.join(Rails.root, "tmp", "bags")
         dest_file = "#{@bag_name}.tar"
         cmd = "cd #{bag_base}; tar cf #{dest_file} #{@bag_name}"
         `#{cmd}`
         return File.join(bag_base, dest_file)
      end

      # Remove all traces of the bag.
      def cleanup 
         @logger.info("Cleanup bag #{@bag_name}")
         if Dir.exist? @bag_dir 
            FileUtils.rm_rf(@bag_dir)
         end
         bag_base = File.join(Rails.root, "tmp", "bags")
         dest_file = "#{@bag_name}.tar"
         tar_file = File.join(bag_base, dest_file)
         FileUtils.rm tar_file if File.exist? tar_file 
      end

      private
      def write_md5(manifest, src_file, rel_path)
         md5 = Digest::MD5.file src_file
         File.open(manifest, 'a') { |io| io.puts "#{md5} #{rel_path}" }
      end

      private
      def write_sha256(manifest, src_file, rel_path)
         sha256 = Digest::SHA256.file src_file
         File.open(manifest, 'a') { |io| io.puts "#{sha256} #{rel_path}" }
      end
   end
end

#s3 = Aws::S3::Client.new(access_key_id: 'key', secret_access_key: 'secret')
#)