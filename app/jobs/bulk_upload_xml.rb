class BulkUploadXml < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      unit = message[:unit]
      unit_dir = "%09d" % unit.id
      xml_dir = File.join(XML_DROPOFF_DIR, "#{unit_dir}")
      if !Dir.exist? xml_dir
         on_error("XML Dropoff directory #{xml_dir} does not exist")
      end

      orig_metadata = unit.metadata
      logger.info "Ingesting XML files from #{xml_dir}"
      cnt = 0
      Dir.glob("#{xml_dir}/*.xml").sort.each do |xf|
         # Read the XML file
         f = File.open(xf, "r")
         xml_str = f.read()
         f.close

         errors = XmlMetadata.validate( xml_str )
         if errors.length > 0
            on_failure("XML File #{xf} has errors and has been skipped. Errors: #{errors.join(',')}")
            next
         end

         # Convert the xml file name into a tif file name and find a matching master file
         xml_name = xf.split("/").last
         tif_name = xml_name.split(".")[0] + ".tif"
         mf = unit.master_files.find_by(filename: tif_name)
         if mf.nil?
            on_failure("Unable to find master file for xml file #{xml_name}")
         else
            cnt += 1

            # Extract title and creator info
            xml = Nokogiri::XML( xml_str )
            xml.remove_namespaces!
            title = orig_metadata.title
            creator = orig_metadata.creator_name
            title_node = xml.xpath( "//titleInfo/title" ).first
            title = title_node.text.strip if !title_node.nil?
            creator_node = xml.xpath("//name/namePart").first
            creator = creator_node.text.strip if !creator_node.nil?

            if mf.metadata == orig_metadata
               # This Master file is still associated with the original unit metadata.
               # Create a new metadata record based on the XML and associate it with the masterfile
               metadata = Metadata.create!(type: "XmlMetadata", title: title, is_approved: orig_metadata.is_approved,
                  discoverability: orig_metadata.discoverability, indexing_scenario_id: 2,
                  desc_metadata: xml_str, use_right_id: orig_metadata.use_right_id,
                  availability_policy: orig_metadata.availability_policy,
                  creator_name: creator, exemplar: mf.filename)
               mf.update(metadata_id: metadata.id)
            else
               # This masterfile already has its own metadata; just update content
               mf.metadata.update(desc_metadata: xml_str, title: title, creator_name: creator)
            end
         end
      end
      logger.info "Updated #{cnt} masterfiles with XML metadata"
   end
end
