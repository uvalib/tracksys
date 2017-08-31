class BulkUploadXml < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def read_settings( settings_file )
      f = File.open(settings_file, "r")
      settings_str = f.read()
      settings_str.gsub!(/\r\n?/, "\n") # normalize linefeed
      f.close

      settings = {}
      settings_str.each_line do |line|
         parts = line.split(":")
         if parts[0].strip.downcase == "discoverability"
            settings[:discoverability] = parts[1].strip == "true"
         elsif parts[0].strip.downcase == "dpla"
               settings[:dpla] = parts[1].strip == "true"
         elsif parts[0].strip.downcase == "availability"
            if parts[1].strip.downcase == "uva"
               settings[:availability] = AvailabilityPolicy.find(3)
            else
               settings[:availability] = AvailabilityPolicy.find(1)
            end
         elsif parts[0].strip.downcase == "rights"
            id = parts[1].strip.to_i
            settings[:rights] = UseRight.find(id)
         end
      end
      return settings
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      unit = Unit.find(message[:unit_id])
      unit_dir = "%09d" % unit.id
      xml_dir = File.join(XML_DROPOFF_DIR, "#{unit_dir}")
      if !Dir.exist? xml_dir
         on_error("XML Dropoff directory #{xml_dir} does not exist")
      end

      # Make sure there is a settings file present. It has settings for
      # Include in DL, availability, rights, and discoverability
      settings_file = File.join(xml_dir, "settings.txt")
      if not File.exist? settings_file
         on_error("XML Dropoff directory #{xml_dir} does not contain settings.txt")
      end
      settings = read_settings( settings_file)

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

            # Extract title and creator info; default to title and creator from unit
            # if the data is not present in the xml
            xml = Nokogiri::XML( xml_str )
            xml.remove_namespaces!

            title = orig_metadata.title
            title_node = xml.xpath( "//titleInfo/title" ).first
            title = title_node.text.strip if !title_node.nil?

            creator = orig_metadata.creator_name
            creator_parts = []
            xml.xpath("//name/namePart").each do |node|
               creator_parts << node.text.strip
            end
            if !creator_parts.blank?
               creator = creator_parts.join(" ")
            end

            dpla = orig_metadata.dpla
            dpla = settings[:dpla] if !settings[:dpla].nil?
            dpla = false if unit.reorder

            if mf.metadata == orig_metadata
               # This Master file is still associated with the original unit metadata.
               # Create a new metadata record based on the XML and associate it with the masterfile
               metadata = Metadata.create!(type: "XmlMetadata", title: title, is_approved: orig_metadata.is_approved,
                  discoverability: settings[:discoverability],
                  desc_metadata: xml_str, use_right: settings[:rights],
                  availability_policy: settings[:availability],
                  creator_name: creator, exemplar: mf.filename,
                  dpla: dpla, parent_metadata_id: orig_metadata.id )
               mf.update(metadata_id: metadata.id)
            else
               # This masterfile already has its own metadata; just update content
               mf.metadata.update(desc_metadata: xml_str, title: title, creator_name: creator,
                  discoverability: settings[:discoverability], use_right: settings[:rights],
                  availability_policy: settings[:availability], dpla: dpla )
            end
         end
      end
      logger.info "Updated #{cnt} masterfiles with XML metadata"
   end
end
