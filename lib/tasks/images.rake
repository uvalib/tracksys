namespace :images do

   desc "Download JP2 for a unit"
   task :download_jp2  => :environment do
      uid = ENV['unit']
      abort("unit is required") if uid.blank?
      unit = Unit.find_by(id: uid)
      abort("Invalid unit id") if unit.nil?

      dest_dir = File.join(Rails.root, "tmp", "jp2_copy", uid )
      FileUtils.mkdir_p dest_dir
      puts "Dowload JP2 to #{dest_dir}"

      unit.master_files.each do |mf|
         jp2_file = mf.iiif_file
         pagenum = mf.filename.split("_")[1].split(".")[0]
         dest_file = File.join(dest_dir, "#{pagenum}.jp2")
         puts "Copy image #{jp2_file} to #{dest_file}"
         FileUtils.copy(jp2_file, dest_file)
         FileUtils.chmod(0664, dest_file)
      end
      puts "DONE"
   end
end