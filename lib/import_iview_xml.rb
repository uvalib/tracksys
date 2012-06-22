# This module provides methods for importing iView (also known as Microsoft
# Expression Media) XML files.
module ImportIviewXml

  require 'nokogiri'  # Use Nokogiri for XML processing; see http://nokogiri.rubyforge.org/

  # Reads the iView XML file passed as XML, and creates records in the
  # database accordingly (one MasterFile record for each iView +MediaItem+
  # element and Component records as needed). Occurrence of any error
  # halts the import process and rolls back any database changes already made.
  #
  # In:
  # 1. An open File object for the XML file to be imported
  # 2. Integer; unit_id value to assign to each new MasterFile object
  # 3. Optional Logger object (for writing to a log file in a batch-import
  #    context)
  # 4. Optional filename (string) of XML file to be imported (for log messages
  #    in a batch-import context)
  #  
  # Out: Returns a hash with these keys:
  # * +:is_manuscript+ (boolean)
  # * +:has_SetList+ (boolean)
  # * +:master_file_count+ (integer; number of MasterFile records imported)
  # * +:component_count+ (integer; number of Component records imported)
  # * +:ead_ref_count+ (integer; number of EadRef records imported)
  # * +:warnings+ (string; warning messages, only applicable in a non-batch
  #   context)
  def self.import_iview_xml(file, unit_id, logger = nil, filename = nil)
    @master_file_count = 0
    @pid_count = 0
    @pids = Array.new
    @info_prefix = "Info|#{filename}|#{unit_id}|"
    @warning_prefix = "WARNING|#{filename}|#{unit_id}|"
    @error_prefix = "ERROR|#{filename}|#{unit_id}|"
    master_files = Hash.new
    has_SetList = false
    warnings = ''  # When in a non-batch context, in some cases warning messages are concatenated in a string rather than raised
    
    # Get Unit object
    begin
      unit = Unit.find(unit_id)
    rescue ActiveRecord::RecordNotFound
      raise ImportWarning, "Can't add Master File records for Unit #{unit_id} because Unit does not exist"
    end
    
    if unit.bibl
      is_manuscript = unit.bibl.is_manuscript?
    else
      is_manuscript = false
    end
    
    # Read XML file
    begin
      doc = Nokogiri.XML(file)
    rescue Exception => e
      raise ImportError, "Can't read file as XML: #{e.message}"
    end
    
    # Check XML for expected elements
    root = doc.root  # "root" returns the root element, in this case <CatalogType>, not the document root preceding any elements
    unless root.name == 'CatalogType'
      raise ImportError, "File does not contain an iView XML document: Root element is <#{root.name}>, but <CatalogType> was expected"
    end
    if root.xpath('MediaItemList').empty?
      raise ImportError, "File does not contain an iView XML document: <MediaItemList> element was not found"
    end
    
    # Read XML to determine number of PIDs needed for this import
    #
    # Note: We must do this in advance, because when processing <Set> elements
    # to add Component records we must save the Component record and use its
    # database-assigned auto-increment id as the parent id for any child
    # Component records. Similarly for ImageTechMeta records, which require a
    # MasterFile id.
    root.xpath('MediaItemList').each do |list|
      list.xpath('MediaItem').each do |item|
        # Each <MediaItem> becomes a MasterFile record
        @pid_count += 1
      end
    end
    if is_manuscript
      # TODO:  Add validation for bibl requiring sets.
    end
    
    # Request pids
    begin
      @pids = AssignPids.request_pids(@pid_count)
    rescue Exception => e
      # ErrorMailer.deliver_notify_pid_failure(e)
    end
    
    # Check for processing instruction indicating software name and version
    format_software = 'iview'
    format_version = nil
    doc.xpath('//processing-instruction()').each do |pi|
      if pi.name == 'iview' or pi.name == 'expression'
        format_software = pi.name
        matches = pi.text.match(/exportversion=["']([^"']*)["']/)
        if matches
          format_version = matches[1]
        end
      end
    end
    
    # Start a database transaction, so all changes get rolled back if an
    # unhandled exception occurs
    MasterFile.transaction do
      begin
        # Create one MasterFile record for each iView <MediaItem>
        root.xpath('MediaItemList').each do |list|
          list.xpath('MediaItem').each do |item|
            element = item.xpath('AssetProperties/UniqueID').first
            iview_id = element.nil? ? nil : element.text
            if iview_id.blank?
              raise ImportError, "Missing or empty <UniqueID> for <MediaItem>"
            end
            
            # instantiate MasterFile object in memory
            master_file = new_master_file(item, unit_id)
            # if a MasterFile with this filename already exists for this Unit, do
            # not overwrite it
            if MasterFile.find(:first, :conditions => ["unit_id = :unit_id AND filename = :filename", {:unit_id => unit_id, :filename => master_file.filename}])
              raise ImportError, "Import failed for Unit #{unit_id}, because a Master File with filename '#{master_file.filename}' already exists for this Unit"
            end
            # if MasterFile object fails validity, raise error with custom error message
            if not master_file.valid?
              raise ImportError, "<MediaItem> with <UniqueID> \"#{iview_id}\" and <Filename> \"#{master_file.filename}\": #{master_file.errors.full_messages}"
            end
            # save MasterFile to database, raising any error that occurs
            master_file.pid = @pids.shift unless @pids.blank?
            # master_file.skip_pid_notification = true  # Don't send email notification if can't obtain pid for this individual record upon save; we already sent one if pid request for entire unit failed
            master_file.save!
            sleep 0.1

            # Determine if this newly created MasterFile's <UniqueID> (now saved in the iview_id variable)
            # is part of a <Set> within this Iview XML.  If so
            setname = root.xpath("//SetName/following-sibling::UniqueID[contains(., '#{iview_id}')]/preceding-sibling::SetName").last.text
            pid = setname[/pid=([-a-z]+:[0-9]+)/, 1]
            link_to_component(master_file.id, pid)

            # also store MasterFile in hash for later use (hash key is iView "UniqueID" value)
            master_files[iview_id] = master_file
            
            # instantiate ImageTechMeta object in memory
            image_tech_meta = new_image_tech_meta(item, master_file.id)
            # if object fails validity, raise error with custom error message
            if not image_tech_meta.valid?
              raise ImportError, "<MediaItem> with <UniqueID> \"#{iview_id}\": #{image_tech_meta.errors.full_messages}"
            end
            # save ImageTechMeta to database, raising any error that occurs
            image_tech_meta.save!
            
            @master_file_count += 1
          end
        end
        
        # # Check for <SetList> element
        # if root.xpath('SetList/Set').empty?
        #   has_SetList = false
        # else
        #   has_SetList = true
        # end

        # if is_manuscript
        #   unless has_SetList
        #     raise ImportError, "Unit pertains to a manuscript, but XML has no <SetList> element"
        #   end
        # else
        #   if has_SetList
        #     # Determine whether <SetList> really contains anything meaningful
        #     set_count = root.xpath('SetList/Set').length
        #     set_name = root.xpath('SetList/Set/SetName').first
        #     if set_count == 1 and set_name and set_name.text == '@KeywordsSet'  # this strange value (some kind of placeholder?) occurs regularly in XML files created by iView; ignore it
        #       # not a meaningful SetList; ignore
        #     else
        #       raise ImportWarning, "Unit does NOT pertain to a manuscript, but XML has a <SetList> element"
        #     end
        #   end
        # end
        
        # If the Unit pertains to a manuscript, and if the XML file includes a
        # <SetList> element, create Component records and assign the Component id
        # to the component_id field of the associated MasterFile record(s).
        # if is_manuscript
        #   root.xpath('SetList').each do |list|
        #     list.xpath('Set').each do |set|
        #       # Since we're in a loop, rescue warnings, so processing can
        #       # continue post-warning if appropriate
        #       begin
        #         # Determine whether to create Component records or EadRef
        #         # records from this top-level <Set>
        #         set_name = set.xpath('SetName').first
        #         if set_name and set_name.text =~ /(^|\s)type\s*=\s*ead/
        #           class_name = 'EadRef'
        #         else
        #           class_name = 'Component'
        #         end
        #         create_component_or_ead_ref(class_name, set, master_files, unit.bibl_id, nil, logger)
        #       rescue ImportWarning => e
        #         if logger.nil?
        #           # not in a batch context
        #           #raise e
        #           warnings += "WARNING: " + e.message + "\n"
        #           next
        #         else
        #           # batch context; log and continue
        #           logger.warn "#{@warning_prefix}#{e.message}"
        #           next
        #         end
        #       end
        #     end
        #   end
        # end
        # root.xpath('SetList').each do |list|
        #   list.xpath('Set').each do |set|
        #     # Since we're in a loop, rescue warnings, so processing can
        #     # continue post-warning if appropriate
        #     begin
        #       # Determine whether to create Component records or EadRef
        #       # records from this top-level <Set>
        #       set_name = set.xpath('SetName').first
        #       if set_name and set_name.text =~ /(^|\s)type\s*=\s*ead/
        #         class_name = 'EadRef'
        #       else
        #         class_name = 'Component'
        #       end
        #       create_component_or_ead_ref(class_name, set, master_files, unit.bibl_id, nil, logger)
        #     rescue ImportWarning => e
        #       if logger.nil?
        #         # not in a batch context
        #         #raise e
        #         warnings += "WARNING: " + e.message + "\n"
        #         next
        #       else
        #         # batch context; log and continue
        #         logger.warn "#{@warning_prefix}#{e.message}"
        #         next
        #       end
        #     end
        #   end
        # end
        
        # Save entire iView XML document for this Unit
        # UPDATE: In practice, some iView XML files exceed the maximum number of bytes MySQL can handle. Instead of storing iView XML documents in database, we should retain them as files on disk.
        unit_import_source = UnitImportSource.new(:unit_id => unit.id)
        #file.rewind
        #unit_import_source.import_source = file.readlines.join('')
        unit_import_source.standard = format_software if format_software
        unit_import_source.version = format_version if format_version
        begin
          unit_import_source.save!
        rescue Exception => e
          raise ImportError, "Unable to save UnitImportSource for Unit #{unit.id}: #{e.message}"
        end
        
      # Note: ImportError is not rescued here (only ImportWarning). Any
      # ImportError will propagate up and roll back the database transaction.
      rescue ImportWarning => e
        # For a warning, in a batch-import context we want to log the warning
        # but continue processing
        if logger.nil?
          # We're not in a batch-import context, so re-raise the exception,
          # thereby rolling back the database transaction
          raise e.message
        else
          # We're in a batch-import context, so log and continue, without
          # rolling back the database transaction
          logger.warn "#{@warning_prefix}#{e.message}"
        end
      end  # end begin block
    end  # end database transaction
    
    # Populate "actual unit extent" field; this is not crucial, so don't raise exceptions on save
    unit.unit_extent_actual = @master_file_count
    unit.save
    
    # If in a batch-import context, compare call number from iView XML
    # against call number from Bibl record in database
    unless logger.nil?
      # get first <Credit> element, which contains the call number
      element = doc.xpath('//Credit').first
      iview_call_number = element.text if element
      bibl_call_number = unit.bibl.call_number if unit.bibl
      begin
        if iview_call_number.blank? and bibl_call_number.blank?
          raise ImportWarning, "Can't compare iView call number to Tracking System call number: no call number value (<Credit> element) in iView XML, and no call number value in Tracking System bibl record"
        elsif iview_call_number.blank?
          raise ImportWarning, "Can't compare iView call number to Tracking System call number '#{bibl_call_number.strip}': no call number value (<Credit> element) in iView XML"
        elsif bibl_call_number.blank?
          raise ImportWarning, "Can't compare iView call number '#{iview_call_number.strip}' to Tracking System call number: no call number value in Tracking System bibl record"
        else
          # compare call number values; warn if not identical
          if iview_call_number.strip == bibl_call_number.strip
            logger.info "#{@info_prefix}iView call number '#{iview_call_number.strip}' = Tracking System call number '#{bibl_call_number.strip}'"
          else
            raise ImportWarning, "iView call number '#{iview_call_number.strip}' is not identical to Tracking System call number '#{bibl_call_number.strip}'"
          end
        end
      rescue ImportWarning => e
        logger.warn "#{@warning_prefix}#{e.message}"
      end
    end
    
    return Hash[:master_file_count => @master_file_count, :component_count => @component_count, :ead_ref_count => @ead_ref_count, :is_manuscript => is_manuscript, :has_SetList => has_SetList, :warnings => warnings]
  end

  #-----------------------------------------------------------------------------
  # private methods
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

  #-----------------------------------------------------------------------------

  # Given that all components are already in Tracksys and have pids, link the 
  # newly created master_file record with an already extant component found by
  # it's pid which is contained in the <SetName> value.
  def self.link_to_component(master_file_id, pid)
    mf = MasterFile.find(master_file_id)
    c = Component.find_by_pid(pid)
    mf.update_attribute(:component_id, c.id)
  end
  private_class_method :link_to_component

  #-----------------------------------------------------------------------------

  # Instantiates a new ImageTechMeta object (in memory, without saving it to
  # the database) and populates it with data from a particular iView XML
  # +MediaItem+ element.
  #  
  # In:
  # 1. iView XML +MediaItem+ element (Nokogiri Element object)
  # 2. MasterFile ID (integer) to assign to the master_file_id field of the
  #    ImageTechMeta object
  #  
  # Out: Returns the resulting ImageTechMeta object
  def self.new_image_tech_meta(item, master_file_id)
    image_tech_meta = ImageTechMeta.new(:master_file_id => master_file_id)
    
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
    
    return image_tech_meta
  end
  private_class_method :new_image_tech_meta

  #-----------------------------------------------------------------------------

  # Instantiates a new MasterFile object (in memory, without saving it to the
  # database) and populates it with data from a particular iView XML
  # +MediaItem+ element.
  #
  # In:
  # 1. iView XML +MediaItem+ element (Nokogiri Element object)
  # 2. Unit ID (integer) to assign to the unit_id field of the MasterFile
  #    object
  #
  # Out: Returns the resulting MasterFile object
  def self.new_master_file(item, unit_id)
    master_file = MasterFile.new(:unit_id => unit_id, :tech_meta_type => 'image')
    
    # filename
    master_file.filename = get_element_value(item.xpath('AssetProperties/Filename').first)
    
    # filesize
    element = item.xpath('AssetProperties/FileSize').first
    if element and element['unit'] and element['unit'].match(/^bytes$/i)
      value = get_element_value(element)
      master_file.filesize = value unless value.to_i == 0
    end
    
    # title
    # In newer iView XML files, title value is in <Headline>
    master_file.title = get_element_value(item.xpath('AnnotationFields/Headline').first)
    
    # notes
    master_file.description = get_element_value(item.xpath('AnnotationFields/Caption').first)
    
    return master_file
  end
  private_class_method :new_master_file


  #-----------------------------------------------------------------------------
  # private supporting classes
  #-----------------------------------------------------------------------------

private

  class ImportError < RuntimeError  #:nodoc:
  end

  class ImportWarning < RuntimeError  #:nodoc:
  end

end
