class ImportRawImages < BaseJob

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'images' is required" if message[:images].blank?
      images = message[:images]
      xml_files = message[:xml_files]
      unit =  message[:unit]
      unit_dir = "%09d" % unit.id
      in_proc_dir = File.join(IN_PROCESS_DIR, unit_dir)

      seq = 1
      images.each do |image|
         # create master file, but name it to tracksys standards. Save original file name in title field.
         src_file = File.join(in_proc_dir, image)
         seq_str = "%04d" % seq
         mf_filename = "#{unit_dir}_#{seq_str}.tif"
         master_file = MasterFile.find_by(unit_id: unit.id, filename: mf_filename)
         if master_file.nil?
            fs = File.size(src_file)
            md5 = Digest::MD5.hexdigest(File.read(src_file) )
            master_file  = MasterFile.create(filename: mf_filename, title: image, filesize: fs, md5: md5, unit_id: unit.id, metadata_id: unit.metadata_id)
            logger.debug "Created master file #{mf_filename}"
         else
            logger.info "Master File with filename '#{master_file.filename}' already exists for this Unit"
         end

         CreateImageTechnicalMetadata.exec_now({master_file: master_file, source: src_file}, self)

         # if XML present, try to match up image -> xml name. Log error if no match
         if !xml_files.empty?
            xml_file = image.gsub(/\.tif/, ".xml")
            if xml_files.include? xml_file
               f = File.open(File.join(in_proc_dir, xml_file), "r")
               xml_str = f.read
               errors = XmlMetadata.validate( xml_str )
               if errors.length > 0
                  on_failure("XML File #{xf} has errors and has been skipped. Errors: #{errors.join(',')}")
               else
                  xml = Nokogiri::XML( xml_str )
                  xml.remove_namespaces!
                  title_node = xml.xpath( "//titleInfo/title" ).first
                  title = title_node.text.strip if !title_node.nil?
                  creator_node = xml.xpath("//name/namePart").first
                  creator = creator_node.text.strip if !creator_node.nil?

                  md = Metadata.create!(type: "XmlMetadata", title: title, is_approved: 1,
                     indexing_scenario_id: 2, desc_metadata: xml_str, creator_name: creator,
                     discoverability: true, availability_policy: unit.metadata.availability_policy,
                     dpla: unit.metadata.dpla, parent_metadata_id: unit.metadata.id, 
                     exemplar: master_file.filename)
                  master_file.update(metadata_id: md.id)
                  logger.debug "Created XML Metadata for master file #{mf_filename}"
               end
            else
               logger.error "#{xml_file} not found. No metadata will be added for #{image}"
            end
         end

         File.rename(src_file, File.join(in_proc_dir, mf_filename))
         seq += 1
      end

      unit.update(unit_extent_actual: seq-1, master_files_count: seq-1)
      logger().info ("Images for Unit #{unit.id} successfully imported. Beginning finalization...")
      unit.order.update_attribute(:date_finalization_begun, Time.now)

      CheckUnitDeliveryMode.exec_now({ :unit_id => unit.id }, self)
   end
end
