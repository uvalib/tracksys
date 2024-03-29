require 'find'
require 'digest/md5'

namespace :archive do
   # archive the contents of the to_fineArts folder if not already archived
   task :guest  => :environment do
      tgt = ENV['dir']
      abort ("'dir' is required") if tgt.nil?
      base_dir = File.join(Settings.production_mount, "guest_dropoff", tgt)
      abort("#{base_dir} does not exist") if !Dir.exist? base_dir

      # list all of the relevant directory names in the base
      cmd = "ls #{base_dir} | grep -v Apple | grep -v DS_Store"
      dir_str = `#{cmd}`
      dirs = dir_str.split("\n")
      cnt = 0
      archived = 0

      # check to see of each directory exists in the archive....
      dirs .each do |src_dir|
         cnt += 1
         archive_dir = File.join(Settings.archive_mount, src_dir)
         if !Dir.exist? archive_dir
            puts "#{archive_dir} does not exist. Archiving..."
            send_to_archive(base_dir, src_dir)
            archived += 1
         else
            print(".")
         end
      end
      puts "Done. Checked #{cnt} directories, archived #{archived}"
   end

   task :update_finearts  => :environment do
      src_dir = ENV['src']
      dest_dir = ENV['dest']
      abort ("'src_dir' is required") if src_dir.nil?
      abort ("'dest_dir' is required") if dest_dir.nil?
      base_src_dir = File.join(Settings.production_mount, "guest_dropoff", "from_fineArts", src_dir)
      abort("#{base_src_dir} does not exist") if !Dir.exist? base_src_dir
      archive_dir = File.join(Settings.archive_mount, dest_dir)
      abort("#{archive_dir} does not exist") if !Dir.exist? archive_dir

      Dir.glob("#{base_src_dir}/*.tif").sort.each do |src|
         puts src
         tif = File.basename(src)
         archive_file = File.join(archive_dir, tif)
         if File.exist? archive_file
            backup_file = "#{archive_file}.orig"
            puts "   backup original to #{backup_file}"
            File.rename(archive_file, backup_file)
         end

         src_md5 = Digest::MD5.hexdigest( File.read(src) )
         FileUtils.copy(src, archive_file )
         FileUtils.chmod(0664, archive_file )
         dest_md5 = Digest::MD5.hexdigest( File.read(archive_file) )
         if src_md5 != dest_md5
            puts "WARN: #{src} failed checksum test!"
         else
            puts "   updated"
         end
      end
      puts "DONE"
   end

   def send_to_archive(base_dir, unit_dir)
      Dir.chdir(base_dir)
      Find.find( unit_dir ) do |f|
         if File.directory?(f)
            FileUtils.makedirs( File.join(Settings.archive_mount, f) )
            FileUtils.chmod(0775, File.join(Settings.archive_mount, f))
         elsif File.file?(f)
            p = Pathname.new(f)
            parent = p.parent.to_s
            basename = p.basename.to_s
            if (/^\./ =~ basename).nil?
               # copy the file...
               archive_file = File.join(Settings.archive_mount, parent, basename)
               FileUtils.copy(f, archive_file)
               FileUtils.chmod(0664, File.join(Settings.archive_mount, parent, basename))

               # get source and archived MD5. Make sure they match
               md5 = Digest::MD5.hexdigest( File.read(f) )
               md5_clone = Digest::MD5.hexdigest( File.read(archive_file) )
               if md5 != md5_clone
                  puts "WARN: #{f} failed checksum test!"
               end
            end
         end
      end
   end
end
