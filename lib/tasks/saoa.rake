namespace :saoa do
   # runs a test export on image from the unit specified
   task :test  => :environment do
      uid = ENV['unit']
      abort ("Unit is required") if uid.nil?
      puts "Generate test deliverables for unit #{uid}"
      unit = Unit.find(uid)
      unit_dir = "%09d" % unit.id
      archive_dir = File.join(ARCHIVE_DIR, unit_dir)
      out_dir = File.join(Rails.root, "tmp", unit_dir)
      if !Dir.exist? out_dir 
         FileUtils.mkdir_p out_dir
      end
      kdu = KDU_COMPRESS || %x( which kdu_compress )
      if !File.exist? kdu 
         about("kdu_compress not found")
      end
      unit.master_files.each do |mf|
         src_file = File.join(archive_dir, mf.filename)
         puts "Generate grayscale JP2K for #{src_file}"
         if !File.exist src_file 
            puts "   ERROR: source not found. Skipping."
            next
         end

         puts "First make it grayscale..."
         gs_out = File.join(out_dir, mf.filename)
         `convert #{src_file} -set colorspace Gray -separate -average -quiet #{gs_out}`
         
         jp2_out = gs_out.gsub /.tif/, ".jp2"
         # `#{kdu} -i #{gs_out} -o #{jp2_out} -rate 1.0,0.5,0.25`
         `convert  #{gs_out} -quality 75 #{jp2_out}`
         puts "   Generated: #{jp2_out}"
      end
   end 
end