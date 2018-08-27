# This module provides methods for importing iView (also known as Microsoft
# Expression Media) XML files to create new MasterFiles and link to existing components.
module ImportIviewXml

   require 'nokogiri'

   # Reads the iView XML file passed as XML, and creates MasterFile records in the
   # database accordingly (one MasterFile record for each iView +MediaItem+
   # element) and links newly create MasterFiles to existing Components (if necessary).
   # Occurrence of any error halts the import process and rolls back any database changes already made.
   def self.import_iview_xml(file, unit, job_logger)
      @master_file_count = 0

      # Read XML file and get the root node ( <CatalogType> )
      job_logger.info "Reading XML file..."
      doc = Nokogiri.XML(file)
      root = doc.root

      # Flag if the XML contains a SetList. If so, it will be used to link to components
      has_set_list = !(root.xpath('//SetList').empty? || root.xpath('//SetList//UniqueID').empty?)

      # Create one MasterFile record for each iView <MediaItem>
      job_logger.info "Creating master files..."
      root.xpath('MediaItemList').each do |list|
         list.xpath('MediaItem').each do |item|
            element = item.xpath('AssetProperties/UniqueID').first
            iview_id = element.nil? ? nil : element.text
            if iview_id.blank?
               on_error "Missing or empty <UniqueID> for <MediaItem>"
            end

            master_file = create_master_file(item, unit, job_logger)
            @master_file_count += 1

            # Only attempt to link MasterFiles with Components if the MasterFile's metadata record is a manuscript item
            # Further, only attempt to do this if SetList data is present. If not, no worries.
            if unit.metadata && unit.metadata.is_manuscript? && has_set_list == true
               # Determine if this newly created MasterFile's <UniqueID> (now saved in the iview_id variable)
               # is part of a <Set> within this Iview XML.  If so grab it and find the PID value.
               #
               # If the setname does not include a PID value, raise an error.
               setname = root.xpath("//SetName/following-sibling::UniqueID[normalize-space()='#{iview_id}']/preceding-sibling::SetName").last.text
               pid = setname[/pid=([-a-z]+:[0-9]+)/, 1]
               job_logger.info "Link manuscript to PID #{pid}"
               if pid.nil?
                  on_error "Setname '#{setname}' does not contain a PID, therefore preventing assignment of Component to MasterFile"
               else
                  link_to_component(master_file.id, pid)
               end
            end
         end
      end

      # Populate "actual unit extent" field; this is not crucial, so don't raise exceptions on save
      unit.update(unit_extent_actual: @master_file_count, master_files_count: @master_file_count)
      return @master_file_count
   end

   #-----------------------------------------------------------------------------
   # private methods
   #-----------------------------------------------------------------------------

   # Given that all components are already in Tracksys and have pids, link the
   # newly created master_file record with an already extant component found by
   # it's pid which is contained in the <SetName> value.
   def self.link_to_component(master_file_id, pid)
      mf = MasterFile.find(master_file_id)
      c = Component.find_by(pid: pid)
      mf.update_attribute(:component_id, c.id)
   end
   private_class_method :link_to_component

   # Create a new ImageTechMeta object and populates it with data from a particular iView XML
   # +MediaItem+ element.
   #
   def self.create_image_tech_meta(item, master_file_id)
      image_tech_meta = ImageTechMeta.new(:master_file_id => master_file_id)
      update_tech_meta(item, image_tech_meta)
   end

   def self.update_tech_meta(item, image_tech_meta)
      value = get_element_value(item.xpath('AssetProperties/MediaType').first)
      if value.to_s.strip.blank?
         # Format is required, so try to infer format from filename extension
         filename = get_element_value(item.xpath('AssetProperties/Filename').first)
         if filename.to_s.strip =~ /\.tiff?$/i
            image_tech_meta.image_format = 'TIFF'
         end
      else
         image_tech_meta.image_format = value
      end

      element = item.xpath('MediaProperties/Width').first
      if element and element['unit'] and element['unit'].match(/^pixels$/i)
         image_tech_meta.width = get_element_value(element)
      end

      element = item.xpath('MediaProperties/Height').first
      if element and element['unit'] and element['unit'].match(/^pixels$/i)
         image_tech_meta.height = get_element_value(element)
      end

      element = item.xpath('MediaProperties/Resolution').first
      image_tech_meta.resolution = get_element_value(element)
      image_tech_meta.color_space = get_element_value(item.xpath('MediaProperties/ColorSpace').first)
      image_tech_meta.color_profile = get_element_value(item.xpath('MediaProperties/ColorProfile').first)
      image_tech_meta.equipment = get_element_value(item.xpath('MetaDataFields/Maker').first)
      image_tech_meta.software = get_element_value(item.xpath('MetaDataFields/Software').first)
      image_tech_meta.model = get_element_value(item.xpath('MetaDataFields/Model').first)
      image_tech_meta.exif_version = get_element_value(item.xpath('MetaDataFields/ExifVersion').first)

      # Have to manipulate the contents of this element due to the native format of 2010:05:31 14:32:42
      # MySQL cannot understand the colons in between the date values.

      # Conditional necessary because CaptureDate is not always included in Iview XML (i.e. during redelivery
      # of older material) and .gsub method on Nil returns an error.
      capture_date = get_element_value(item.xpath('MetaDataFields/CaptureDate').first)
      if capture_date
         capture_date.gsub(/(\d\d\d\d):(\d\d):(\d\d)/, '\1-\2-\3')
      end
      image_tech_meta.capture_date = capture_date

      image_tech_meta.iso = get_element_value(item.xpath('MetaDataFields/ISOSpeedRating').first)
      image_tech_meta.exposure_bias = get_element_value(item.xpath('MetaDataFields/ExposureBias').first)
      image_tech_meta.exposure_time = get_element_value(item.xpath('MetaDataFields/ExposureTime').first)
      image_tech_meta.aperture = get_element_value(item.xpath('MetaDataFields/Aperture').first)
      image_tech_meta.focal_length = get_element_value(item.xpath('MetaDataFields/FocalLength').first)

      element = item.xpath('MediaProperties/Depth').first
      if element and element['unit'] and element['unit'].match(/^bits$/i)
         image_tech_meta.depth = get_element_value(element)
      end

      # The meaning of element <Compression> in iView XML is not obvious; in
      # examples I've seen, value is an integer, not the name of a compression
      # scheme:
      #   <Compression>65537</Compression>
      #   <PrimaryEncoding>TIFF (Uncompressed)</PrimaryEncoding>
      element = item.xpath('MediaProperties/Compression').first
      if element
         value = element.text
         if value.match(/^\d+$/)
            # value is an integer; check whether <PrimaryEncoding> value contains "Uncompressed"
            element2 = item.xpath('MediaProperties/PrimaryEncoding').first
            if element2
               value2 = element2.text
               if value2.match(/Uncompressed/)
                  image_tech_meta.compression = 'Uncompressed'
               end
            end
         else
            # value is not an integer; assume value is name of a compression string
            image_tech_meta.compression = value unless value.blank?
         end
      end

      # save ImageTechMeta to database, raising any error that occurs
      if !image_tech_meta.save
         on_error
            "Unable to create/update tech metadata for #{image_tech_meta.master_file_id}: #{image_tech_meta.errors.full_messages}"
      end
   end
   private_class_method :create_image_tech_meta

   # Create a new MasterFile object and populates it with data from a particular iView XML
   # +MediaItem+ element.
   #
   def self.create_master_file(item, unit, logger)
      # get the filename and find it on the filesystem. If it is in a subfolder
      # use this info to create a location record for the masterfile
      tgt_filename = get_element_value(item.xpath('AssetProperties/Filename').first)
      in_proc = Finder.finalization_dir(unit, :in_process)
      full_path = Dir[File.join(in_proc, "/**/#{tgt_filename}")].first
      if full_path.blank?
         on_error "Missing master file #{tgt_filename}"
      end

      # get the directory of the tgt file and strip off the base
      # in_process dir. The remaining bit will be the subdirectory  or nothing.
      # use this info to know if there is box/folder info encoded in the filename
      subdir_str = File.dirname(full_path)[in_proc.length+1..-1]

      # See if this masterfile has already been created...
      master_file = MasterFile.find_by(unit_id: unit.id, filename: tgt_filename )
      if master_file.nil?
         # Nope... create a new one and fill in properties with data from xml
         logger.info "Create new master file #{tgt_filename}"
         master_file = MasterFile.new(filename: tgt_filename,
            unit_id: unit.id, metadata_id: unit.metadata_id)

         element = item.xpath('AssetProperties/FileSize').first
         if element && element['unit'] && element['unit'].match(/^bytes$/i)
            value = get_element_value(element)
            master_file.filesize = value.to_i
         else
            master_file.filesize = File.size(full_path)
         end

         master_file.title = get_element_value(item.xpath('AnnotationFields/Headline').first)
         master_file.description = get_element_value(item.xpath('AnnotationFields/Caption').first)

         if !master_file.save
            on_error "<MediaItem> with <Filename> '#{master_file.filename}': #{master_file.errors.full_messages}"
         end
      else
         logger.info "Master file #{tgt_filename} already exists"
      end

      if !subdir_str.blank? && master_file.location.nil? && !unit.project.nil?
         # subdir structure: [box|oversize|tray].{box_name}/{folder_name}
         logger.info "Creating location metadata based on subdirs [#{subdir_str}]"
         location = Location.find_or_create(unit.metadata, unit.project.container_type, in_proc, subdir_str)
         master_file.set_location(location)
      end

      # Get tech metadata and transcriptions
      create_image_tech_meta(item, master_file.id) if master_file.image_tech_meta.nil?
      get_transcription_text(master_file)

      return master_file
   end
   private_class_method :create_master_file

   #-----------------------------------------------------------------------------

   # Returns the text content of the XML element passed, or nil if element is
   # nil/blank.
   def self.get_element_value(element)
      if element.nil?
         value = nil
      else
         value = element.text.strip
         value = nil if value.blank?
      end
      return value
   end
   private_class_method :get_element_value

   # Reads text file (if present) matching MF filename and adds it as transcription text
   def self.get_transcription_text(master_file)
      in_proc = Finder.finalization_dir(master_file.unit, :in_process)
      text_file = master_file.filename.gsub(/\..*$/, '.txt')
      text_file_fqn = File.join(in_proc, text_file)
      if File.exist?(text_file_fqn)
         text = nil
         begin
            text = File.read(text_file_fqn)
         rescue
            text = "" unless text
         end
         master_file.update(transcription_text: text)
      end
   end

   # Reads iView XML file and raises errors if various criteria are not met
   # returns nil on successful QA of Nokogiri::XML object, returns array
   # of error strings otherwise
   public
   def self.qa_iview_xml(xml, unit=nil)
      errors=[]
      unless xml.kind_of? Nokogiri::XML::Document
         errors << "#{__method__} did not receive Nokogiri::XML::Document as argument."
      end
      if xml.namespaces
         xml.remove_namespaces!
      end

      # main sanity checks

      # "root" returns the root element, in this case <CatalogType>, not the document root preceding any elements
      root = xml.root

      # Check XML for expected elements
      unless root.name == 'CatalogType'
         errors << "File does not contain an iView XML document: Root element is <#{root.name}>, but <CatalogType> was expected"
      end
      if root.xpath('MediaItemList').empty?
         errors << "File does not contain an iView XML document: <MediaItemList> element was not found"
      end

      # Extra checks for SetList (used to link MasterFiles to Component hierarchy)
      if unit.metadata && unit.metadata.is_manuscript?

         # If SetList is empty, just carry on. This to allow manuscript units with
         # no components to be flagged properly
         if root.xpath('//SetList').empty? || root.xpath('//SetList//UniqueID').empty?
            return
         end

         media_item_list = root.xpath('//MediaItemList//UniqueID').map(&:content)
         set_list = root.xpath('//SetList//UniqueID').map(&:content)

         # A SetList is present. Make sure it is valid. Are ID counts the same?
         if media_item_list.count == set_list.count
            # count might be OK, but identifiers must be all accounted for (order may differ)
            if media_item_list.sort != set_list.sort
               if media_item_list != ( media_item_list|set_list )    # media_item_list is missing a UniqueID
                  errors << "iView Catalog #{unit.id} has images appearing in Catalog Sets which have no technical metadata in Iview XML"
               elsif set_list != ( media_item_list|set_list )        # set_list is missing a UniqueID
                  errors << "iView Catalog #{unit.id} has images in it not assigned to Catalog Sets"
               else
                  errors << "All I know is media_item_list != set_list: got media_item_list:#{media_item_list.inspect} != set_list:#{set_list.inspect}"
               end
            end
         else
            # Counts are different. Generate a differences report for the error log
            # The diff below will be blank if the count discrepancy was caused by duplicate
            # entries in the set_list data. Ignore this type of error as it doesn't cause any
            # problems limnking items from media items list  to component pids in set list
            report = media_item_list - set_list
            if report.count > 0
               errors << "IView Catalog #{unit.id} has an unequal number of UniqueID's in MediaItem and SetList nodes.  Missing IDs: #{report}"
            end
         end
      end

      # report and return
      if errors != []
         errors
      else #passed QA
         nil
      end
   end
end
