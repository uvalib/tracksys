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
      archive_dir = File.join(ARCHIVE_DIR, unit_dir)

      page_num = 1
      list.each do |info|
         src_mf = MasterFile.find_by(id: info[:id])
         if src_mf.nil?
            on_failure "Unable to find master file with ID #{info[:id]}. Skipping."
            next
         end

         archived_mf = File.join(arvhive_dir,mf.filename)
         if not File.exist? archived_mf
            on_failure "Unable to find archived tif for master file with ID #{info[:id]}. Skipping."
            next
         end

         logger.info "Cloning master file #{mf.id}: #{mf.filename}"
         padded_page = "%04d" % page_num
         new_fn = "#{unit_dir}_#{padded_page}.tif"
         dest_file = FileUtils.join(in_proc_dir,new_fn)
         FileUtils.cp( FileUtils.join(archive_dir, archive_dir.filename), dest_file)
         md5 = Digest::MD5.hexdigest(File.read(dest_file) )
         if md5 != src_mf.md5
            on_failure "Checksum mismatch for master file with ID #{info[:id]}. Skipping."
            next
         end

         MasterFile.create(
            unit_id: unit.id, filename: new_fn, filesize: src_mf.filesize,
            title: info[:title], description: src_mf.description,
            transcription_text: src_mf.transcription_text,
            md5: src_mf.md5, creator_death_date: src_mf.creator_death_date,
            creation_date: src_mf.creation_date, primary_author: src_mf.primary_author,
            metadata_id: src_mf.metadata_id)

            page_num += 1
      end

      logger.info "All masterfiles cloned into unit #{unit.id}. Flagging unit as cloned"
      unit.update(cloned: true)
   end
end
