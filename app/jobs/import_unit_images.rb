class ImportUnitImages < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      # Get unit and path to unit
      unit = Unit.find(message[:unit_id])
      logger.info "Source Unit: #{unit.to_json}"
      unit_path = Finder.finalization_dir(unit, :in_process)
      logger.info "Import images from #{unit_path}"


      begin
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
                  fatal_error "exiftool was unable to extract metadata from #{tgt_filename}"
               end
               md = JSON.parse(exif_out).first
               if md['Headline'].blank?
                  fatal_error "#{tgt_filename} is missing Headline"
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
                  fatal_error "#{tgt_filename}' : #{master_file.errors.full_messages}"
               end

            else
               logger.info "Master file #{tgt_filename} already exists"
            end

            # Get tech metadata....
            if master_file.image_tech_meta.nil?
               logger.info "Create tech metadata for  #{tgt_filename}"
               TechMetadata.create(master_file, mf_path)
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
         unit.update(unit_extent_actual: mf_count, master_files_count: mf_count)

         logger().info( "Images for Unit #{unit.id} successfully imported.")
      rescue Exception=>e
         fatal_error("Import images for Unit #{unit.id} FAILED: #{e.message}")
      end

      logger().info ("Beginning finalization...")
      unit.order.update_attribute(:date_finalization_begun, Time.now)
      logger().info("Date Finalization Begun updated for order #{unit.order.id}")

      CheckUnitDeliveryMode.exec_now({ :unit_id => unit.id }, self)
   end
end
