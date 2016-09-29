class BulkUploadXml < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      unit = message[:unit]
      unit_dir = "%09d" % unit.id
      xml_dir = File.join(XML_DROPOFF_DIR, "#{unit_dir}")
      orig_metadata = unit.metadata
      logger.info "Ingesting XML files from #{xml_dir}"
      cnt = 0
      Dir.glob("#{xml_dir}/*.xml").sort.each do |xf|
         # Read the XML file
         f = File.open(xf, "r")
         xml_str = f.read()
         f.close

         # Convert the xml file name into a tif file name and find a matching master file
         xml_name = xf.split("/").last
         tif_name = xml_name.split(".")[0] + ".tif"
         mf = unit.master_files.find_by(filename: tif_name)
         if mf.nil?
            on_failure("Unable to find master file for xml file #{xml_name}")
         else
            cnt += 1

            # some desc_metadata has namespaces, some does not.
            # figure out if this one does, and set params to be used in xpath
            ns = ""
            ns = "mods:" if xml_str.include? "xmlns:mods"

            # Extract title and creator info
            xml = Nokogiri::XML( xml_str )
            title = orig_metadata.title
            creator = orig_metadata.creator_name
            title_node = xml.xpath( "//#{ns}titleInfo/#{ns}title" ).first
            if !title_node.nil?
               title = title_node.text.strip
            end
            creator_node = xml.xpath("//#{ns}name/#{ns}namePart").first
            creator = creator_node.text if !creator_node.nil?

            # Create the new metadata record and associate it with the masterfile
            metadata = Metadata.create!(type: "XmlMetadata", title: title, is_approved: orig_metadata.is_approved,
               discoverability: orig_metadata.discoverability, indexing_scenario_id: 2,
               desc_metadata: xml_str, use_right_id: orig_metadata.use_right_id,
               availability_policy: orig_metadata.availability_policy,
               creator_name: creator, exemplar: mf.filename)
            mf.update(metadata_id: metadata.id)
         end
      end
      logger.info "Updated #{cnt} masterfiles with XML metadata"
   end
end
