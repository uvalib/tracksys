# This module provides methods for importing iView (also known as Microsoft
# Expression Media) XML files to create new MasterFiles and link to existing components.
module ImportIviewXml

  require 'nokogiri'

  # Reads the iView XML file passed as XML, and creates MasterFile records in the
  # database accordingly (one MasterFile record for each iView +MediaItem+
  # element) and links newly create MasterFiles to existing Components (if necessary).
  # Occurrence of any error halts the import process and rolls back any database changes already made.
  #
  # In:
  # 1. An open File object for the XML file to be imported
  # 2. Integer; unit_id value to assign to each new MasterFile object
  #
  # Out: Returns a hash with these keys:
  # * +:is_manuscript+ (boolean)
  # * +:has_SetList+ (boolean)
  # * +:master_file_count+ (integer; number of MasterFile records imported)
  # * +:warnings+ (string; warning messages, only applicable in a non-batch
  #   context)
  def self.import_iview_xml(file, unit_id)
    Rails.logger.info "ImportIvewXML: importing #{unit_id}"
    @master_file_count = 0
    @pid_count = 0
    @pids = Array.new

    # Get Unit object
    begin
      unit = Unit.find(unit_id)
    rescue ActiveRecord::RecordNotFound
      raise ImportError, "Can't add Master File records for Unit #{unit_id} because Unit does not exist"
    end

    # Read XML file
    begin
      doc = Nokogiri.XML(file)
    rescue Exception => e
      raise ImportError, "Can't read file as XML: #{e.message}"
    end

    # "root" returns the root element, in this case <CatalogType>, not the document root preceding any elements
    root = doc.root

    error_list = qa_iview_xml(doc, unit)
    if error_list != [] && error_list != nil
      raise ImportError, "qa_iview_xml found errors: #{error_list.to_s}"
    end

    # Read XML to determine number of PIDs needed for this import
    # This is done in advance to alleviate the number of calls made
    # to the API for Fedora.
    root.xpath('MediaItemList').each do |list|
      list.xpath('MediaItem').each do |item|
        # Each <MediaItem> becomes a MasterFile record
        @pid_count += 1
      end
    end

    # Request pids
    begin
      @pids = AssignPids.request_pids(@pid_count)
    rescue Exception => e
      # TODO: Restore ErrorMailer
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
    retry_attempts = 5 # for database deadlocks during large transactions
    begin
    MasterFile.transaction do
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
          # if there are .txt files in folder matching MasterFile filenames, add them as transcriptions
          if ImportIviewXml.get_transcription_text(master_file)
            Rails.logger.debug "ImportIvewXML: getting transcription for #{master_file.filename}"
          end
          master_file.save!
          sleep 0.3

          # Only attempt to link MasterFiles with Components if the MasterFile's Bibl record is a manuscript item
          if unit.bibl && unit.bibl.is_manuscript?
            # Determine if this newly created MasterFile's <UniqueID> (now saved in the iview_id variable)
            # is part of a <Set> within this Iview XML.  If so grab it and find the PID value.
            #
            # If the setname does not include a PID value, raise an error.
            setname = root.xpath("//SetName/following-sibling::UniqueID[normalize-space()='#{iview_id}']/preceding-sibling::SetName").last.text
            pid = setname[/pid=([-a-z]+:[0-9]+)/, 1]
            Rails.logger.info "Link manuscript to PID #{pid}"
            if pid.nil?
              raise ImportError, "Setname '#{setname}' does not contain a PID, therefore preventing assignment of Component to MasterFile"
            else
              link_to_component(master_file.id, pid)
            end
          end

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
    end  # end database transaction
    @current_caller = caller[0][/`([^']*)'/, 1]
    Rails.logger.info "[#{Time.now}] #{@current_caller}: MasterFile batch transaction completed (#{@pid_count} items)."
    rescue ActiveRecord::StatementInvalid => e # or Mysql2::Error
      Rails.logger.warn "#{@current_caller}: Caught Mysql2 exeption #{e.message}"
      if retry_attempts > 0
        amount = 300 / retry_attempts # take more time on successive attempts
        Rails.logger.info "[#{Time.now}] #{@current_caller}: Sleeping for #{300/retry_attempts}s and retrying transaction"
        sleep amount
        ActiveRecord::Base.connection.reconnect!
        Rails.logger.info "[#{Time.now}] #{self.class} retrying transaction now."
        retry
      else
        report = "Exceeded retry limit: unable to overcome #{e.inspect}"
        Rails.logger.error report
        raise RuntimeError, report # will send failure message to bus, storing report in db
      end
      retry_attempts -= 1
    end


    # Populate "actual unit extent" field; this is not crucial, so don't raise exceptions on save
    unit.unit_extent_actual = @master_file_count
    unit.save
    return Hash[:master_file_count => @master_file_count]
  end

  #-----------------------------------------------------------------------------
  # private methods
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

  # Reads text file (if present) matching MF filename and adds it as
  # transcription text
  def self.get_transcription_text(master_file, dir=nil)
    unit_dir = sprintf('%09d', master_file.unit.id)
    dir ||= "#{IN_PROCESS_DIR}/#{unit_dir}"
    text_file = master_file.filename.gsub(/\..*$/, '.txt')
    text_file_fqn = "#{dir}/#{text_file}"
    if File.exist?(text_file_fqn)
      text = nil
      begin
        text = File.read(text_file_fqn)
      rescue
        text = "" unless text
      end
      master_file.transcription_text = text
    else
      nil
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
    if unit.bibl && unit.bibl.is_manuscript?
      media_item_list=root.xpath('//MediaItemList//UniqueID').map(&:content)
      set_list=root.xpath('//SetList//UniqueID').map(&:content)
      if root.xpath('//SetList').empty?
        errors << "iView Catalog #{unit.id} has no SetList, but Unit #{unit.id} has Bibl flagged as Manuscript Item"
      elsif media_item_list.sort != set_list.sort # count might be OK, but identifiers must be all accounted for (order may differ)
        if media_item_list != ( media_item_list|set_list ) # media_item_list is missing a UniqueID
          errors << "iView Catalog #{unit.id} has images appearing in Catalog Sets which have no technical metadata in Iview XML"
        elsif set_list != ( media_item_list|set_list ) # set_list is missing a UniqueID
          errors << "iView Catalog #{unit.id} has images in it not assigned to Catalog Sets"
        else
          errors << "All I know is media_item_list != set_list: got media_item_list:#{media_item_list.inspect} != set_list:#{set_list.inspect}"
        end
      elsif root.xpath('//MediaItem//UniqueID').count != root.xpath('//SetList//UniqueID').count
        report = []
        if media_item_list > set_list
          report = media_item_list - set_list
        else
          report = set_list - media_item_list
        end
        errors << "IView Catalog #{unit.id} has an unequal number of UniqueID's in MediaItem and SetList nodes.  Missing IDs: #{report}"
      end
    end

    # report and return
    if errors != []
      errors
    else #passed QA
      nil
    end
  end

  #-----------------------------------------------------------------------------
  # private supporting classes
  #-----------------------------------------------------------------------------

private

  class ImportError < RuntimeError  #:nodoc:
  end

end
