module Images

   def self.import(unit, logger = Logger.new(STDOUT))
      unit_path = File.join(Settings.production_mount, "finalization", unit.directory)
      logger.info "Import images from #{unit_path}"
      if unit.throw_away
         logger.info "This unit is a throw away and will not be archived."
      end

      assemble_dir = ""
      call_number = nil
      location = nil
      if unit.reorder == false &&  unit.intended_use.description != "Digital Collection Building" && unit.intended_use.deliverable_format != "pdf"
         logger.info "This unit requires patron deliverables. Setting up working directories."
         assemble_dir = File.join(Settings.production_mount, "finalization", "tmp", unit.directory)
         FileUtils.mkdir_p(assemble_dir) if !Dir.exist? assemble_dir
         logger.info "Deliverables will be generated in #{assemble_dir}"

         if unit.metadata.type == "SirsiMetadata"
            sm = unit.metadata.becomes(SirsiMetadata)
            call_number = sm.call_number
            marc_metadata = sm.get_full_metadata
            if !marc_metadata.nil?
               location = marc_metadata[:location]
            end
         end
      end

      # iterate through all of the .tif files in the unit directory
      mf_count = 0
      Dir.glob(File.join(unit_path, "**/*.tif")).sort.each do |mf_path|
         logger.info "Import #{mf_path}"
         tgt_filename = File.basename(mf_path)
         mf_count += 1

            # See if this masterfile has already been created...
         master_file = MasterFile.find_by(unit_id: unit.id, filename: tgt_filename )
         if master_file.nil?
            # Nope... create a new one and fill in properties from exif
            logger.info "Create new master file #{tgt_filename}"
            master_file = MasterFile.new(filename: tgt_filename, unit_id: unit.id, metadata_id: unit.metadata_id)

            # get filesize bytes, headline and caption then save
            master_file.filesize = File.size(mf_path)
            cmd = "exiftool -json -iptc:OwnerID -iptc:headline -iptc:caption-abstract #{mf_path}"
            exif_out = `#{cmd}`
            if exif_out.blank?
               raise "exiftool was unable to extract metadata from #{tgt_filename}"
            end
            md = JSON.parse(exif_out).first
            if md['Headline'].blank?
               raise "#{tgt_filename} is missing Headline"
            end
            master_file.title = md['Headline']
            master_file.description = md['Caption-Abstract']

            if !md['OwnerID'].blank? && unit.metadata && unit.metadata.is_manuscript?
               cid = md['OwnerID']
               logger.info "Link master file #{tgt_filename} to component #{cid}"
               c = Component.find_by(id: cid)
               if c.blank?
                  logger.warn "Could not find component #{cid} to link to master file #{tgt_filename}"
               else
                  master_file.component_id = c.id
               end
            end

            if !master_file.save
               raise "#{tgt_filename}' : #{master_file.errors.full_messages}"
            end

         else
            logger.info "Master file #{tgt_filename} already exists"
         end

         if master_file.image_tech_meta.nil?
            logger.info "Create tech metadata for  #{tgt_filename}"
            TechMetadata.create(master_file, mf_path)
         end

         if unit.reorder == false
            logger.info("Publishing #{master_file.filename} to IIIF...")
            IIIF.publish(mf_path, master_file, false, logger)

            if unit.throw_away == false && unit.date_archived.blank?
               Archive.publish(mf_path, master_file, logger)
            end

            if unit.intended_use.description != "Digital Collection Building" && unit.intended_use.deliverable_format != "pdf"
               logger.info "Create patron deliverable for #{master_file.filename}"
               deliverable_file = Patron.create_deliverable(unit, master_file, mf_path, assemble_dir, call_number, location, logger)
            end
         end

         # check for transcription text file
         text_file = master_file.filename.gsub(/\..*$/, '.txt')
         text_file_fqn = File.join(unit_path, text_file)
         if File.exist?(text_file_fqn)
            logger.info "Add transcription text for  #{tgt_filename}"
            text = nil
            begin
               text = File.read(text_file_fqn)
            rescue
               text = "" unless text
            end
            master_file.update(transcription_text: text)
         end

         # mf_path is the full path to the image. Strip off the base
         # in_process dir. The remaining bit will be the subdirectory or nothing.
         # use this info to know if there is box/folder info encoded in the filename
         subdir_str = File.dirname( mf_path )[unit_path.length+1..-1]
         if !subdir_str.blank? && master_file.location.nil? && !unit.project.nil?
            # subdir structure: [box|oversize|tray].{box_name}/{folder_name}
            logger.info "Creating location metadata based on subdirs [#{subdir_str}]"
            if unit.project.container_type.nil?
               unit.project.container_type = ContainerType.first
               unit.project.save!
               logger.warn "Location data available, but container type not set. Defaulting to #{unit.project.container_type.name}"
            end
            location = Location.find_or_create(unit.metadata, unit.project.container_type, unit_path, subdir_str)
            master_file.set_location(location)
            logger.info "Created location metadata for [#{subdir_str}]"
         end
      end

      logger.info("#{mf_count} master files ingested")
      unit.update(unit_extent_actual: mf_count, master_files_count: mf_count, date_archived: Time.now)
      logger.info "Date Archived set to #{unit.date_archived} for for unit #{unit.id}"
      Archive.check_order_archive_complete(unit.order, logger)

      logger.info( "Images for Unit #{unit.id} successfully imported.")
   end

   def self.cleanup(unit, logger = Logger.new(STDOUT) )
      logger.info("Cleaning up unit #{unit.directory} directories")
      tmp_dir = File.join(Settings.production_mount, "finalization", "tmp")
      work_dir = File.join(tmp_dir, unit.directory)
      if Dir.exist? work_dir
         FileUtils.rm_rf(work_dir)
      end

      src_dir = File.join(Settings.production_mount, "finalization", unit.directory)
      del_dir =  File.join(Settings.production_mount, "ready_to_delete", unit.directory)
      logger.info "Moving #{unit.directory} to #{del_dir}"
      if Dir.exist? del_dir
         logger.info "#{del_dir} already exists; cleaning it up"
         FileUtils.rm_rf(del_dir)
      end
      FileUtils.mv(src_dir, del_dir, force: true)
   end
end
