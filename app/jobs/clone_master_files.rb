class CloneMasterFiles < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)
      unit = message[:unit]

      # List of master files to clone. Form: {id, title}
      list = message[:list]

      # Create new MF records and pull tiffs from archive into in_proc for the new unit
      # so they will be ready to be used to generate deliverables with
      # the RecreatePatronDeliverables job
      unit_dir = "%09d" % unit.id
      in_proc_dir = File.join(IN_PROCESS_DIR, unit_dir)
      FileUtils.mkdir_p(in_proc_dir) if !Dir.exist? in_proc_dir

      page_num = 1
      list.each do |info|
         src_mf = MasterFile.find_by(id: info[:id])
         if src_mf.nil?
            on_failure "Unable to find master file with ID #{info[:id]}. Skipping."
            next
         end

         archive_dir = File.join(ARCHIVE_DIR, src_mf.filename.split("_")[0])
         archived_mf = File.join(archive_dir, src_mf.filename)
         if not File.exist? archived_mf
            on_failure "Unable to find archived tif #{archived_mf} for master file with ID #{info[:id]}. Skipping."
            next
         end

         if src_mf.md5.blank?
            on_failure "Archived file #{archived_mf} #{mf.pid} is missing checksum. Calculating now."
            md5 = Digest::MD5.hexdigest(File.read(archived_mf) )
            src_mf.update(md5: md5)
         end

         logger.info "Cloning master file #{src_mf.id}: #{src_mf.filename}"
         padded_page = "%04d" % page_num
         new_fn = "#{unit_dir}_#{padded_page}.tif"
         dest_file = File.join(in_proc_dir, new_fn)
         FileUtils.cp( archived_mf, dest_file)
         md5 = Digest::MD5.hexdigest(File.read(dest_file) )
         if md5 != src_mf.md5
            on_failure "Checksum mismatch for master file with ID #{info[:id]}. Skipping."
            next
         end

         mf = MasterFile.create(
            unit_id: unit.id, filename: new_fn, filesize: src_mf.filesize,
            title: info[:title], description: src_mf.description,
            transcription_text: src_mf.transcription_text,
            md5: src_mf.md5, creator_death_date: src_mf.creator_death_date,
            creation_date: src_mf.creation_date, primary_author: src_mf.primary_author,
            metadata_id: src_mf.metadata_id, original_mf_id: src_mf.id)

         tm = src_mf.image_tech_meta
         ImageTechMeta.create(master_file_id: mf.id,
            image_format: tm.image_format, width: tm.width, height: tm.height,
            resolution: tm.resolution, color_space: tm.color_space, depth: tm.depth,
            compression: tm.compression, color_profile: tm.color_profile,
            equipment: tm.equipment, software: tm.software, model: tm.model,
            exif_version: tm.exif_version, capture_date: tm.capture_date, iso: tm.iso,
            exposure_bias: tm.exposure_bias, exposure_time: tm.exposure_time,
            aperture: tm.aperture, focal_length: tm.focal_length  )

         page_num += 1
      end

      old_cnt = unit.master_files_count
      logger.info "#{old_cnt+list.size} masterfiles cloned into unit #{unit.id}. Flagging unit as cloned"
      unit.update(reorder: true, master_files_count: (old_cnt+list.size) )
   end
end
