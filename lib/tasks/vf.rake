#encoding: utf-8

namespace :vf do
   desc "Generate fake tifs for dev testing"
   task :fake  => :environment do
      dir = ARCHIVE_DIR
      unit_dir = "000003198"
      thumb_dir = "000003198/Thumbnails_(000003198)"
      for num in 1..910 do
         filename = "#{unit_dir}_#{num.to_s.rjust(3, '0')}.tif"
         fn = File.join(dir, unit_dir, filename)
         f = File.open(fn, "w")
         f.close

         filename = "#{unit_dir}_#{num.to_s.rjust(3, '0')}.jpg"
         fn = File.join(dir, thumb_dir, filename)
         f = File.open(fn, "w")
         f.close
      end
   end

   desc "Rename files to collapse skipped page numbers"
   task :renumber  => :environment do
      u = Unit.find(3198)
      unit_dir_name = "000003198"
      thumb_dir_name = "000003198/Thumbnails_(000003198)"
      dir = File.join(ARCHIVE_DIR, unit_dir_name)
      thumb_dir = File.join(ARCHIVE_DIR, thumb_dir_name)

      # First, remove the two bad files, 61 and 908
      puts "Remove bad pages 61 and 908..."
      bad = ["000003198_061", "000003198_908"]
      bad.each do |f|
         tf = File.join(dir, "#{f}.tif")
         File.delete( tf ) if File.exist?(tf)
         jf = File.join(thumb_dir, "#{f}.jpg")
         File.delete( jf ) if File.exist?(jf)
      end

      puts "Renumber all pages to fill gaps..."
      prior = nil
      u.master_files.order("filename asc").each do |mf|
         num = mf.filename.split('.')[0].split('_')[1].to_i
         if !prior.nil?
            update = false
            while num != (prior+1) do
               update = true
               num = num - 1
            end

            if update
               # update tif
               new_name = "#{mf.filename.split("_")[0]}_#{num.to_s.rjust(3, '0')}.tif"
               File.rename(File.join(dir, mf.filename), File.join(dir, new_name))

               # update thumb
               new_name = "#{mf.filename.split("_")[0]}_#{num.to_s.rjust(3, '0')}.jpg"
               old =  mf.filename.gsub(/.tif/, '.jpg')
               File.rename(File.join(thumb_dir, old), File.join(thumb_dir, new_name))

               # update db rec
               mf.filename = new_name
               mf.save!
            end
         end
         prior = num
      end
   end

   desc "ingest VanityFair MODS xml (src=src_dir default /digiserv-production)"
   task :add_mods => :environment do
      src = ENV['src']
      src = "/digiserv-production" if src.nil?

      dir = "#{src}/migration/VanityFair/Vanity_Fair_MODS_records"
      puts "Pulling MODS from #{dir}..."
      Dir.glob("#{dir}/*.xml") do |f|
         file = File.open(f, "rt")
         contents = file.read
         file.close
         fn = f.split("/").last.gsub(/.mods.xml/,'')
         mf = MasterFile.where(filename: fn).first
         if mf.nil?
            puts "** ERROR ** No master file for #{fn}"
         else
            mf.desc_metadata = contents
            if !mf.save
               puts "** ERROR ** Unable to save changes to #{fn}: #{mf.errors.full_messages.to_sentence}"
            else
               puts "UPDATED #{mf.id}"
            end
         end
      end
   end
end
