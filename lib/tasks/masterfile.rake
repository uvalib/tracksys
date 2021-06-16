namespace :masterfile do
   def publish_to_iiif(mf, source_tif)
      # get dettination path
      jp2k_path = mf.iiif_file()
      puts "   IIIF destination: #{jp2k_path}"

      # Make sure tiff is not compressed
      tiff = nil
      temp_file = nil
      begin
         tiff = Magick::Image.read(source_tif).first
      rescue Exception => e
         puts "ERROR reading #{source_tif}: #{e}"
         return
      end
      unless tiff.compression.to_s == "NoCompression"
          temp_file = Tempfile.new([mf.filename.split(".")[0], ".tif"] )
          puts "   writing uncompresed tif to #{temp_file.path}"
          cmd = "convert -quiet #{source_tif} -compress None #{temp_file.path}"
          `#{cmd}`
          source_tif = temp_file.path
      end
      tiff.destroy!

      kdu = KDU_COMPRESS || %x( which kdu_compress ).strip
      if !File.exist?(kdu)
         puts "   Missing KDU can't generate JP2K file"
      else
         `#{kdu} -i #{source_tif} -o #{jp2k_path} -rate 1.0,0.5,0.25 -num_threads 2`
      end
      temp_file.unlink if !temp_file.nil?
   end
end
