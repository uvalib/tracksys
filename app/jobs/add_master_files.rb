class AddMasterFiles < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def validate_tif_files_and_mode(tif_files, unit)
      new_page = -1
      prev_page = -1
      tif_files.each do |tf|
         filename = File.basename(tf)
         if /\A\d{9}_\d{4}.(tif)\z/.match(filename).nil?
            fatal_error("Invalid master file name: #{filename}")
         end

         page_num = filename.split("_").last.split(".").first.to_i
         if new_page == -1
            new_page = page_num
            prev_page = new_page
         else
            fatal_error("Gap in sequence number of new master files") if page_num > prev_page+1
            prev_page = page_num
         end
      end

      last_page = unit.master_files.last.filename.split("_").last.split(".").first.to_i

      fatal_error("New master file sequence number gap (from #{last_page} to #{new_page})") if  new_page > last_page+1

      @mode = :append
      @mode = :insert if new_page <= last_page
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      unit = Unit.find(message[:unit_id])
      unit_dir = "%09d" % unit.id
      archive_dir = File.join(ARCHIVE_DIR, unit_dir)
      xml_files = []
      tif_files = []
      src_dir = Finder.update_dir(unit)
      logger.info "Looking for new *.tif and *.xml files in #{src_dir}"
      tif_files = Dir.glob("#{src_dir}/**/*.tif").sort
      xml_files = Dir.glob("#{src_dir}/**/*.xml").sort

      fatal_error("No tif files found.") if tif_files.count == 0
      fatal_error("Count mismatch between tif and xml files.") if xml_files.count > 0 && xml_files.count != tif_files.count

      @mode = nil
      validate_tif_files_and_mode(tif_files, unit)

      if @mode == :insert
         # rename/rearchive files to make room for new files to be inserted
         # If components are involved, return the ID of the component at the insertion point
         component_id = make_gap_for_insertion(unit, archive_dir, tif_files)
      end

      # grab the first existing master file and see if it has location data.
      # if it does, the cotainer type for all will be the same. pull it
      container_type = nil
      if !unit.master_files.first.nil? && !unit.master_files.first.location.nil?
         container_type = unit.master_files.first.location.container_type
      end

      # Create new master files for the tif file found in the src dir
      logger.info "Adding #{tif_files.count} new master files..."
      tif_files.each do |mf_path|
         # create MF and tech metadata
         fs = File.size(mf_path)
         md5 = Digest::MD5.hexdigest(File.read(mf_path) )
         fn = File.basename(mf_path)
         pg_num = fn.split("_").last.split(".").first.to_i
         master_file  = MasterFile.create(filename: fn, title: pg_num.to_s, filesize: fs, md5: md5,
            unit_id: unit.id, component_id: component_id, metadata_id: unit.metadata_id)
         logger.info "Created master file #{mf_path}"
         CreateImageTechnicalMetadata.exec_now({master_file: master_file, source: mf_path}, self)

         # See if directories are present, and use them to generate location metadata for the file
         if !container_type.nil?
            subdir_str = File.dirname(mf_path)[src_dir.length+1..-1]
            location = Location.find_or_create(unit.metadata, container_type, src_dir, subdir_str)
            master_file.set_location(location) if !location.nil?
         end

         # if XML present, try to match up image -> xml name. Log error if no match
         if !xml_files.empty?
            add_xml_metadata(unit, master_file, mf_path, xml_files)
         end

         # send to IIIF
         PublishToIiif.exec_now({source: mf_path, master_file_id: master_file.id}, self)

         # archive file, validate checksum and set archived date
         new_archive = File.join(archive_dir, fn)
         logger.info "Archiving new master file #{mf_path} to #{new_archive}"
         FileUtils.copy(mf_path, new_archive)
         FileUtils.chmod(0664, new_archive)
         new_md5 = Digest::MD5.hexdigest(File.read(new_archive) )
         log_failure("MD5 does not match for new MF #{new_archive}") if new_md5 != md5
         master_file.update(date_archived: Time.now)

      end

      cnt = unit.master_files_count
      logger.info "Updating unit master files count from #{cnt} to #{cnt+tif_files.size}"
      unit.update(master_files_count: cnt+tif_files.size)

      MoveCompletedDirectoryToDeleteDirectory.exec_now({unit_id: unit.id, source_dir: src_dir}, self)
   end

   private
   def add_xml_metadata(unit, master_file, mf_path, xml_files)
      xml_file = mf_path.gsub(/\.tif/, ".xml")
      if xml_files.include? xml_file
         f = File.open( xml_file, "r")
         xml_str = f.read
         errors = XmlMetadata.validate( xml_str )
         if errors.length > 0
            log_failure("XML File #{xf} has errors and has been skipped. Errors: #{errors.join(',')}")
         else
            xml = Nokogiri::XML( xml_str )
            xml.remove_namespaces!
            title_node = xml.xpath( "//titleInfo/title" ).first
            title = title_node.text.strip if !title_node.nil?
            creator_node = xml.xpath("//name/namePart").first
            creator = creator_node.text.strip if !creator_node.nil?
            dpla = unit.metadata.dpla
            dpla = false if unit.reorder

            md = Metadata.create!(type: "XmlMetadata", title: title,
               desc_metadata: xml_str, creator_name: creator,
               availability_policy: unit.metadata.availability_policy,
               dpla: dpla, parent_metadata_id: unit.metadata.id)
            master_file.update(metadata_id: md.id, exemplar: true)
            logger.debug "Created XML Metadata for master file #{fn}"
         end
      else
         logger.error "#{xml_file} not found. No metadata will be added for #{fn}"
      end
   end

   private
   def make_gap_for_insertion(unit, archive_dir, tif_files)
      tgt_file = File.basename(tif_files.first)
      gap_size = tif_files.count
      component_id = nil
      logger.info "Renaming/rearchiving all master files from #{tgt_file} to make room for insertion of #{gap_size} new master files"
      MasterFile.unscoped.where(unit_id: unit.id).order(filename: :desc).each do |mf|
         if mf.filename == tgt_file
            component_id = mf.component_id
            done = true
         end

         # make sure there is an md5 hash
         archive_file = File.join(archive_dir, mf.filename)
         md5 = mf.md5
         if md5.blank?
            md5 = Digest::MD5.hexdigest(File.read(archive_file) )
            mf.update(md5: md5)
         end

         # figure out new filename and rename/re-title
         orig_fn = mf.filename
         orig_page_num = mf.filename.split("_").last.split(".").first.to_i
         pg_num = orig_page_num + gap_size
         new_fn = "#{mf.filename.split('_').first}_#{'%04d' % pg_num}.tif"
         new_title = mf.title
         if new_title.to_i.to_s == new_title && new_title.to_i == orig_page_num
            new_title = "#{new_title.to_i + gap_size}"
         end
         logger.info "Rename #{mf.filename} to #{new_fn}. Title #{new_title}"
         mf.update(filename: new_fn, title: new_title)

         # copy archived file to new name and validate checksums
         new_archive = File.join(archive_dir, new_fn)
         logger.info "Rename archived file #{archive_file} -> #{new_fn}"
         File.rename(archive_file, new_archive)
         new_md5 = Digest::MD5.hexdigest( File.read(new_archive) )
         fatal_error("MD5 does not match for rename #{archive_file} -> #{new_archive}") if new_md5 != md5

         break if done == true
      end
      return component_id
   end
end
