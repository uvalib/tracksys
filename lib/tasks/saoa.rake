namespace :saoa do
   task :unit   => :environment do
      uid = ENV['id']
      unit = Unit.find(uid)
      abort "Unit #{uid} not found" if unit.nil?
      puts "Generate SAOA jpg and metadata for Unit #{uid}"

      xsl = File.join(Rails.root, "lib", "saoa", "mods2SAOA.xsl")
      saxon = "java -jar #{File.join(Rails.root, "lib", "Saxon-HE-9.7.0-8.jar")}"
      mods = '<mods:modsCollection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mods="http://www.loc.gov/mods/v3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd">\n'

      puts "Get XML metadata"
      xml_md = Hydra.desc(unit.metadata)
      base_fn = unit.staff_notes
      if base_fn.empty? 
         abort "Unit #{unit.id} missing staff notes data."
      end
      oclc = base_fn.split("_").first
      mods << "\n" << xml_md.gsub(/<\?xml.*\?>/, "")


      unit_dir = "%09d" % unit.id
      archive_dir = File.join(ARCHIVE_DIR, unit_dir)
      out_dir = File.join(Rails.root, "saoa", oclc, "jpg")
      if !Dir.exist? out_dir 
         FileUtils.mkdir_p out_dir
      end

      puts "Generate JPG deliverables..."
      unit.master_files.each do |mf|
         src_file = File.join(archive_dir, mf.filename)
         if !File.exist? src_file 
            puts "   ERROR: source #{src_file} not found. Skipping."
            next
         end

         seq = mf.filename.split(".").first.split("_").last.to_i
         seq = "%05d" % seq
         jpg_out = File.join(out_dir, "#{base_fn}_#{seq}.jpg")
         cmd = "convert -quiet #{src_file} -set colorspace Gray -separate -average -strip -interlace Plane -gaussian-blur 0.05 -quality 25% #{jpg_out}"
         `#{cmd}`
         puts "   Generated grayscale JPG for #{src_file}"
      end

      puts "Convert to SAOA..."
      mods << "\n</mods:modsCollection>"
      tmp_mods = Tempfile.new(["saoa_mods", ".xml"])
      tmp_mods.write(mods)
      tmp_mods.close

      cmd = "#{saxon} -s:#{tmp_mods.path} -xsl:#{xsl}"
      saoa_xml = `#{cmd}`
      tmp_saoa = Tempfile.new(["converted", ".xml"])
      tmp_saoa.write( saoa_xml )
      tmp_saoa.close

      puts "Postprocess results into CSV..."
      sed_apos =  "-e \"s/\\&apos;/\\'/g\""
      sed = "sed -ne '/<xmlData/,/<\\/xmlData>/p' |sed -e 's/<xmlData>//' -e 's/<\\/xmlData>//' -e 's/\\&amp;/\\&/g' #{sed_apos} -e 's/\\&gt;/>/g' -e 's/\\&lt;/</g'"
      csv = `cat #{tmp_saoa.path} | #{sed}`
      
      puts "Write results to file..."
      saoa_dir = File.join(Rails.root, "saoa")
      File.open(File.join(saoa_dir,"saoa_u#{uid}.csv"), 'w') { |file| file.write(csv) }

      puts "DONE"
   end

   # target order is 10675
   task :generate_metadata  => :environment do
      oid = ENV['order']
      oid = 10675 if oid.nil?
      order = Order.find(oid)
      abort "Order #{oid} not found" if order.nil?
      puts "Generate SAOA metadata for Order #{oid}"

      cnt = 0
      xsl = File.join(Rails.root, "lib", "saoa", "mods2SAOA.xsl")
      saxon = "java -jar #{File.join(Rails.root, "lib", "Saxon-HE-9.7.0-8.jar")}"
      mods = '<mods:modsCollection xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mods="http://www.loc.gov/mods/v3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd">\n'
      order.units.where("unit_status=? and master_files_count > 0", "approved").each do |unit| 
         puts "#{cnt+1}: Get XML metadata for unit #{unit.id}"
         xml_md = Hydra.desc(unit.metadata)
         base_fn = unit.staff_notes
         if base_fn.empty? 
            puts "   ERROR: Unit #{unit.id} missing staff notes data. Skipping."
            next
         end
         mods << "\n" << xml_md.gsub(/<\?xml.*\?>/, "")
         cnt+=1
      end

      puts "Convert to #{cnt} MODs to SAOA..."
      mods << "\n</mods:modsCollection>"
      tmp_mods = Tempfile.new(["saoa_mods", ".xml"])
      tmp_mods.write(mods)
      tmp_mods.close

      cmd = "#{saxon} -s:#{tmp_mods.path} -xsl:#{xsl}"
      saoa_xml = `#{cmd}`
      tmp_saoa = Tempfile.new(["converted", ".xml"])
      tmp_saoa.write( saoa_xml )
      tmp_saoa.close

      puts "Postprocess results into CSV..."
      sed_apos =  "-e \"s/\\&apos;/\\'/g\""
      sed = "sed -ne '/<xmlData/,/<\\/xmlData>/p' |sed -e 's/<xmlData>//' -e 's/<\\/xmlData>//' -e 's/\\&amp;/\\&/g' #{sed_apos} -e 's/\\&gt;/>/g' -e 's/\\&lt;/</g'"
      csv = `cat #{tmp_saoa.path} | #{sed}`
      
      puts "Write results to file..."
      saoa_dir = File.join(Rails.root, "saoa")
      File.open(File.join(saoa_dir,"saoa.csv"), 'w') { |file| file.write(csv) }
      puts "DONE. #{cnt} MODs records processed"
   end

   # target order is 10675
   task :generate_jpg  => :environment do
      oid = ENV['order']
      oid = 10675 if oid.nil?
      order = Order.find(oid)
      abort "Order #{oid} not found" if order.nil?
      puts "Generate SAOA deliverables for Order #{oid}"
      
      units_processed = 0
      skipped_images = 0
      skipped_units = 0
      img_cnt = 0
      order.units.where("unit_status=? and master_files_count > 0", "approved").each do |unit| 
         # OCLC info has been added to the staff_notes field; retrieve it
         puts "Get XML metadata for unit #{unit.id}"
         base_fn = unit.staff_notes
         if base_fn.empty? 
            puts "   ERROR: Unit #{unit.id} missing staff notes data. Skipping."
            skipped_units+=1
            next
         end
         oclc = base_fn.split("_").first

         unit_dir = "%09d" % unit.id
         archive_dir = File.join(ARCHIVE_DIR, unit_dir)
         out_dir = File.join(Rails.root, "saoa", oclc, "jpg")
         if !Dir.exist? out_dir 
            FileUtils.mkdir_p out_dir
         else
            file_cnt = Dir.glob("#{out_dir}/*.jpg").count
            if file_cnt == unit.master_files.count 
               puts "Destination exists and has all JPG files. Skipping"
               skipped_units+=1
               next
            end
         end

         puts "Generate JPG deliverables..."
         unit.master_files.each do |mf|
            src_file = File.join(archive_dir, mf.filename)
            if !File.exist? src_file 
               puts "   ERROR: source #{src_file} not found. Skipping."
               skipped_images +=1
               next
            end

            seq = mf.filename.split(".").first.split("_").last.to_i
            seq = "%05d" % seq
            jpg_out = File.join(out_dir, "#{base_fn}_#{seq}.jpg")
            if !File.exist? jpg_out
               cmd = "convert -quiet #{src_file} -set colorspace Gray -separate -average -strip -interlace Plane -gaussian-blur 0.05 -quality 25% #{jpg_out}"
               `#{cmd}`
               puts "   Generated grayscale JPG for #{src_file}"
            else
               puts "   Grayscale JPG for #{src_file} already exists"
            end
            img_cnt += 1
         end
         units_processed +=1 
      end

      puts "DONE: #{units_processed} units processed; #{skipped_units} units skipped;"
      puts "      #{img_cnt} images generated; #{skipped_images} images skipped"
   end 
end