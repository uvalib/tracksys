namespace :saoa do
   # sample test unit: 53743
   # runs a test export on image from the unit specified
   task :test  => :environment do
      uid = ENV['unit']
      abort ("Unit is required") if uid.nil?
      puts "Generate test deliverables for unit #{uid}"

      unit = Unit.find(uid)
      unit_dir = "%09d" % unit.id
      archive_dir = File.join(ARCHIVE_DIR, unit_dir)
      out_dir = File.join(Rails.root, "saoa", unit_dir)
      if !Dir.exist? out_dir 
         FileUtils.mkdir_p out_dir
      end

      unit.master_files.each do |mf|
         src_file = File.join(archive_dir, mf.filename)
         puts "Generate grayscale JPG for #{src_file}"
         if !File.exist? src_file 
            puts "   ERROR: source not found. Skipping."
            next
         end

         base_fn = File.basename(mf.filename, File.extname(mf.filename))
         jpg_out = File.join(out_dir, "#{base_fn}.jpg")
         cmd = "convert #{src_file} -set colorspace Gray -separate -average -quality 75 #{jpg_out}"
         puts cmd
         `#{cmd}`
         puts "   Generated: #{jpg_out}"
         abort "stop"
      end
   end 
end
