class CloneMasterFiles < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      unit = Unit.find(message[:unit_id])
      logger.info "Source Unit: #{unit.to_json}"

      # List of master files to clone. Form: {id, title} or {unit: id}
      list = message[:list]

      page_num = 1
      list.each do |info|
         if !info[:unit].blank?
            page_num += clone_all_master_files( info[:unit], unit, page_num )
            next
         end

         src_mf = MasterFile.find_by(id: info[:id])
         if src_mf.nil?
            log_failure "Unable to find master file with ID #{info[:id]}. Skipping."
            next
         end

         next if clone_master_file(unit, src_mf, info[:title], page_num) == false

         page_num += 1
      end

      logger.info "#{page_num-1} masterfiles cloned into unit #{unit.id}. Flagging unit as cloned"
      unit.update(reorder: true, master_files_count: (page_num-1) )
   end

   def clone_all_master_files(src_unit_id, dest_unit, page_num )
      src_unit = Unit.find_by(id: src_unit_id)
      if src_unit.nil?
         log_failure "Unable to find unit with ID #{info[:id]}. Skipping."
         return 0
      end

      logger.info "Cloning all master files from unit #{src_unit_id}"
      pg = page_num
      cloned = 0
      src_unit.master_files.each do |src_mf|
         next if clone_master_file(dest_unit, src_mf, src_mf.title, pg) == false
         pg += 1
         cloned += 1
      end
      return cloned
   end

   def clone_master_file(unit, src_mf, new_title, page_num)
      # Create new MF records and pull tiffs from archive into in_proc for the new unit
      # so they will be ready to be used to generate deliverables with
      # the RecreatePatronDeliverables job
      unit_dir = "%09d" % unit.id
      in_proc_dir = Finder.finalization_dir(unit, :in_process)
      FileUtils.mkdir_p(in_proc_dir) if !Dir.exist? in_proc_dir

      archive_dir = File.join(ARCHIVE_DIR, src_mf.filename.split("_")[0])
      archived_mf = File.join(archive_dir, src_mf.filename)
      if not File.exist? archived_mf
         fatal_error "Unable to find archived tif #{archived_mf} for master file with ID #{src_mf.id}."
      end

      if src_mf.md5.blank?
         log_failure "Archived file #{archived_mf} #{src_mf.pid} is missing checksum. Calculating now."
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
         log_failure "WARNING: Checksum mismatch for master file with ID #{src_mf.id}."
      end

      mf = MasterFile.create(
         unit_id: unit.id, filename: new_fn, filesize: src_mf.filesize,
         component_id: src_mf.component_id,
         title: new_title, description: src_mf.description,
         transcription_text: src_mf.transcription_text,
         md5: src_mf.md5,
         creation_date: src_mf.creation_date, primary_author: src_mf.primary_author,
         metadata_id: src_mf.metadata_id, original_mf_id: src_mf.id)

      if !src_mf.location.nil?
         mf.set_location(src_mf.location)
      end

      tm = src_mf.image_tech_meta
      ImageTechMeta.create(master_file_id: mf.id,
         image_format: tm.image_format, width: tm.width, height: tm.height,
         resolution: tm.resolution, color_space: tm.color_space, depth: tm.depth,
         compression: tm.compression, color_profile: tm.color_profile,
         equipment: tm.equipment, software: tm.software, model: tm.model,
         exif_version: tm.exif_version, capture_date: tm.capture_date, iso: tm.iso,
         exposure_bias: tm.exposure_bias, exposure_time: tm.exposure_time,
         aperture: tm.aperture, focal_length: tm.focal_length  )
   end
end
