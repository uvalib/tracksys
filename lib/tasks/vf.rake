#encoding: utf-8

namespace :vf do

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
