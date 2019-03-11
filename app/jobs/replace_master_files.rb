class ReplaceMasterFiles < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      unit = Unit.find(message[:unit_id])
      unit_dir = "%09d" % unit.id
      archive_dir = File.join(ARCHIVE_DIR, unit_dir)

      tif_files = []
      src_dir = Finder.update_dir(unit)
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

         # update MF attributes, replace tech metadata, re-publish and archive
         curr_mf.update(filesize: fs, md5: md5)
         curr_mf.image_tech_meta.destroy if !curr_mf.image_tech_meta.nil?
         CreateImageTechnicalMetadata.exec_now({master_file: curr_mf, source: mf_path}, self)
         PublishToIiif.exec_now({source: mf_path, master_file_id: curr_mf.id, overwrite: true}, self)

         # archive file and validate checksum
         new_archive = File.join(archive_dir, fn)
         FileUtils.copy(mf_path, new_archive)
         FileUtils.chmod(0664, new_archive)
         new_md5 = Digest::MD5.hexdigest(File.read(new_archive) )
         log_failure("MD5 does not match for new MF #{new_archive}") if new_md5 != md5
      end

      MoveCompletedDirectoryToDeleteDirectory.exec_now({unit_id: unit.id, source_dir: src_dir}, self)
   end
end
