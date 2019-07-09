namespace :saoa do
   # target order is 10675
   task :generate  => :environment do
      oid = ENV['order']
      abort ("Order is required") if oid.nil?
      order = Order.find(oid)
      abort "Order #{oid} not found" if order.nil?
      puts "Generate SAOA deliverables for Order #{oid}"
      
      xsl = File.join(Rails.root, "lib", "saoa", "mods2SAOA.xsl")
      saxon = "java -jar #{File.join(Rails.root, "lib", "Saxon-HE-9.7.0-8.jar")}"
      mods = '<mods:modsCollection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mods="http://www.loc.gov/mods/v3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd">\n'

      units_processed = 0
      skipped_images = 0
      img_cnt = 0
      order.units.where("unit_status=? and master_files_count > 0", "approved").each do |unit| 
         unit_dir = "%09d" % unit.id
         archive_dir = File.join(ARCHIVE_DIR, unit_dir)
         out_dir = File.join(Rails.root, "saoa", unit.metadata.pid)
         if !Dir.exist? out_dir 
            FileUtils.mkdir_p out_dir
         end

         # Get the MODs metadata and remove the <?xml header as it will be added to 
         # the mods collection, which already has this defined
         puts "Get XML metadata for unit #{unit.id}"
         xml_md = Hydra.desc(unit.metadata)
         mods << "\n" << xml_md.gsub(/<\?xml.*\?>/, "")

         puts "Generate JPG deliverables..."
         unit.master_files.each do |mf|
            src_file = File.join(archive_dir, mf.filename)
            if !File.exist? src_file 
               puts "   ERROR: source not found. Skipping."
               skipped_images +=1
               next
            end

            base_fn = File.basename(mf.filename, File.extname(mf.filename))
            jpg_out = File.join(out_dir, "#{base_fn}.jpg")
            cmd = "convert -quiet #{src_file} -set colorspace Gray -separate -average -quality 75 #{jpg_out}"
           `#{cmd}`
            puts "   Generated grayscale JPG for #{src_file}"
            img_cnt += 1
         end
         # FIXME remove me
         units_processed +=1 
         if units_processed  > 2 
            puts "Stopping after a few test generations"
            break
         end
      end

      puts "Convert to MODs to SAOA..."
      mods << "\n</mods:modsCollection>"
      tmp_mods = Tempfile.new(["saoa_mods", ".xml"])
      tmp_mods.write(mods)
      tmp_mods.close
#     puts "MODS SRC: #{mods}"

      cmd = "#{saxon} -s:#{tmp_mods.path} -xsl:#{xsl}"
      saoa_xml = `#{cmd}`
      tmp_saoa = Tempfile.new(["converted", ".xml"])
      tmp_saoa.write( saoa_xml )
      tmp_saoa.close
#     puts "SAOA SRC: #{saoa_xml}"

      puts "Postprocess results into CSV..."
      sed_apos =  "-e \"s/\\&apos;/\\'/g\""
      sed = "sed -ne '/<xmlData/,/<\\/xmlData>/p' |sed -e 's/<xmlData>//' -e 's/<\\/xmlData>//' -e 's/\\&amp;/\\&/g' #{sed_apos} -e 's/\\&gt;/>/g' -e 's/\\&lt;/</g'"
      csv = `cat #{tmp_saoa.path} | #{sed}`
#     puts "SAOA CSV: #{csv}"
      
      puts "Write results to file..."
      saoa_dir = File.join(Rails.root, "saoa")
      File.open(File.join(saoa_dir,"saoa.csv"), 'w') { |file| file.write(csv) }

      puts "DONE; #{units_processed} units processed; #{img_cnt} images generated; #{skipped_images} images skipped"
   end 

   # Target Order: https://tracksys.lib.virginia.edu/admin/orders/10675
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

      puts "Get XML metadata for #{uid}"
      tmp_mods = Tempfile.new([unit.metadata.pid, ".xml"])
      tmp_mods.write(Hydra.desc(unit.metadata))
      tmp_mods.close
      xsl = File.join(Rails.root, "lib", "saoa", "mods2SAOA.xsl")
      saxon = "java -jar #{File.join(Rails.root, "lib", "Saxon-HE-9.7.0-8.jar")}"

      puts "Convert to MODs to SAOA..."
      cmd = "#{saxon} -s:#{tmp_mods.path} -xsl:#{xsl}"
      saoa_xml = `#{cmd}`
      tmp_saoa = Tempfile.new([unit.metadata.pid, ".saoa"])
      tmp_saoa.write( saoa_xml )
      tmp_saoa.close

      puts "Postprocess results into CSV..."
      sed_apos =  "-e \"s/\\&apos;/\\'/g\""
      sed = "sed -ne '/<xmlData/,/<\\/xmlData>/p' |sed -e 's/<xmlData>//' -e 's/<\\/xmlData>//' -e 's/\\&amp;/\\&/g' #{sed_apos} -e 's/\\&gt;/>/g' -e 's/\\&lt;/</g'"
      csv = `cat #{tmp_saoa.path} | #{sed}`

      puts "Generate JPG deliverables..."
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