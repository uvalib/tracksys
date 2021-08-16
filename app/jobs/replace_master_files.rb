class ReplaceMasterFiles < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      unit = Unit.find(message[:unit_id])
      archive_dir = File.join(ARCHIVE_DIR, unit.directory)
      src_dir = File.join(Settings.production_mount, "finalization", "unit_update", unit.directory)

      logger.info "Looking for replacement *.tif files in #{src_dir}"
      tif_files = Dir.glob("#{src_dir}/*.tif").sort
      if tif_files.count == 0
         fatal_error("No replacement *.tif files found")
      end

      tif_files.each do |mf_path|
         fs = File.size(mf_path)
         md5 = Digest::MD5.hexdigest(File.read(mf_path) )
         fn = File.basename(mf_path)
         logger.info("Replacing master file #{fn}")
         curr_mf = unit.master_files.find_by(filename: fn)
         if curr_mf.nil?
            log_failure("File #{fn} was not found in unit. Skipping")
            next
         end

         # update MF attributes
         curr_mf.filesize = fs
         curr_mf.md5 = md5
         cmd = "exiftool -json -iptc:headline -iptc:caption-abstract #{mf_path}"
         exif_out = `#{cmd}`
         if exif_out.blank?
            log_failure "exiftool was unable to extract metadata from #{mf_path}"
         else
            md = JSON.parse(exif_out).first
            if md['Headline'].blank?
               log_failure "#{mf_path} is missing Headline"
            else
               curr_mf.title = md['Headline']
            end
            curr_mf.description = md['Caption-Abstract']
         end
         if !curr_mf.save
            log_failure "Unable to save updates to #{mf_path}: #{curr_mf.errors.full_messages.to_sentence}"
         end

         #replace tech metadata, re-publish and archive
         curr_mf.image_tech_meta.destroy if !curr_mf.image_tech_meta.nil?
         TechMetadata.create(curr_mf, mf_path)
         IIIF.publish(mf_path, curr_mf, true, logger)

         # archive file and validate checksum
         new_archive = File.join(archive_dir, fn)
         FileUtils.copy(mf_path, new_archive)
         FileUtils.chmod(0664, new_archive)
         new_md5 = Digest::MD5.hexdigest(File.read(new_archive) )
         log_failure("MD5 does not match for new MF #{new_archive}") if new_md5 != md5
      end

      logger.info "Cleaning up working files"
      FileUtils.rm_rf(src_dir)
      del_dir =  File.join(Settings.production_mount, "ready_to_delete", unit.directory)
      logger.info "Moving update dir #{src_dir} to #{del_dir}"
      if Dir.exist? del_dir
         logger.info "#{del_dir} already exists; cleaning it up"
         FileUtils.rm_rf(del_dir)
      end
      FileUtils.mv(src_dir, del_dir, force: true)
   end
end
