class QaFilesystemAndIviewXmlProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010
  
  subscribes_to :qa_filesystem_and_iview_xml, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :import_unit_iview_xml

  require 'nokogiri'
  
  def on_message(message)
    logger.tagged("MS3UF") { logger.debug "QaFilesystemAndIviewXmlProcessor received: " + message }

    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Validate incoming message
    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank? 

    # Set unit variables
    @unit_id = hash[:unit_id]
    @unit_dir = "%09d" % @unit_id
    @working_unit = Unit.find(@unit_id)
    @messagable_id = hash[:unit_id]
    @messagable_type = "Unit"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)

    # Create error message holder array
    @error_messages = Array.new

    # Create a series of arrays to hold the files contained within the entry directory so that each type
    # of expected and unexpected files can be tested for compliance.
    @content_files = Array.new
    @xml_files = Array.new
    @ivc_files = Array.new
    @unknown_files = Array.new
   
    # Read contents of hash into an array
    unit_dir_contents = Dir.entries(File.join(IN_PROCESS_DIR, @unit_dir))

    #  Run through every file in the entry directory
    unit_dir_contents.each { |unit_dir_content|
      if (unit_dir_content.eql?(".") | unit_dir_content.eql?(".."))
      else
        # Remove ._ resource fork files
        if (unit_dir_content =~ /^._/)
          File.delete(File.join(IN_PROCESS_DIR, @unit_dir, unit_dir_content))
          # Remove .DS_Store* files produced by Mac OSX
        elsif (unit_dir_content =~ /.DS/)
          File.delete(File.join(IN_PROCESS_DIR, @unit_dir, unit_dir_content))
        elsif (unit_dir_content =~ /.ivc_[0-9]/)
          File.delete(File.join(IN_PROCESS_DIR, @unit_dir, unit_dir_content))
        elsif (unit_dir_content =~ /.(tif|jp2)$/) 
          @content_files.push(unit_dir_content)
        elsif (unit_dir_content =~ /.xml$/)
          @xml_files.push(unit_dir_content)
        elsif (unit_dir_content =~ /Thumbnails/)
        elsif (unit_dir_content) =~ /.txt/
        elsif (unit_dir_content =~ /.ivc$/)
          @ivc_files.push(unit_dir_content)
        elsif (unit_dir_content !~ /(.git$|.md5|.txt$)/) # safe to ignore (.txt files are OCR data typically)
          @unknown_files.push(unit_dir_content)
          logger.debug "QaFilesystemAndIviewXmlProcessor pushing: " + unit_dir_content + " to @unknown_files"
        end
      end
    }
    
    check_content_files
    check_xml_files
    check_ivc_files
    check_thumb_dir
    check_unknown_files
    handle_errors
  end
  
  def check_content_files
    # Checking for:
    # 1. Existence of TIF/JPEG2000 files.
    # 2. The number of content files in the directory equals the sequence number of the last file.
    # 3. All TIF/JPEG2000 files conform to the naming convention.
    # 4. No file is less than 1MB (1MB being a size arbitrarily determined to represent a "too small" file)
    @minimum=2048
    
    if @content_files.empty?
      @error_messages.push("There are no .tif files in the directory.")
    else
      # Check that the number of .tif files in the entry directory equals the sequence number of the last file
      @content_files.sort!
      @number_content_files = @content_files.length
      last_content_file = @content_files.last
      
      # Pull out the sequence number through multiple regex substitutions
      unit_regex = Regexp.new(@unit_dir)
      sequence_number = last_content_file.sub(unit_regex, '')
      sequence_number = sequence_number.sub(/.(tif|jp2)/, '')
      sequence_number = sequence_number.sub(/^_0*/, '')
      
      if (sequence_number != @number_content_files.to_s)
        @error_messages.push("The number of tif/jp2 files in directory (#{@number_content_files}) does not equal the sequence number of the last file (#{sequence_number}).")
      end      
      
      # Define regex to ensure the file ends with an _, followed by four digits followed by .tif or .jp2
      regex_content_file = Regexp.new('_\d{4}.(tif|jp2)$')
      
      @content_files.each { |content_file|
        # Check that the content file begins with the unit number
        if content_file !~ /^#{@unit_dir}/
          @error_messages.push("#{content_file} does not start with the correct unit #{@unit_dir}")       
        end
        # Check the fila part of the tif/jp2 file
        if regex_content_file.match(content_file).nil?
          @error_messages.push("#{content_file} has an incorrectly formatted sequence number or extension.")
        end       
        # Check that the content file is greater than 1MB.
        if File.size(File.join(IN_PROCESS_DIR, @unit_dir, content_file)) < @minimum
          @error_messages.push("#{content_file} is less than #{@minimum} bytes large and is very likely an incorrect file.")
        end
      }
    end    
  end
  
  def check_xml_files
    # Checking for:
    # 1. Existence of a XML file
    # 2. That there is only one XML file
    # 3. That the XML file conforms to naming conventions.
    # 4. That the XML file is not an unacceptably small file.
    
    if @xml_files.empty?
      @error_messages.push("There is no .xml file in the directory.")
    elsif @xml_files.length != 1
      # Check if there is more than one XML file in the directory
      @error_messages.push("There is more than one xml file in the directory.")
    elsif File.size(File.join(IN_PROCESS_DIR, @unit_dir, @xml_files.at(0))) < 100
      @error_messages.push("#{@xml_files.at(0)} is empty.")
    else
      # If any of the three tests above fail, then the test below won't because there is no definitive file.
      
      # Pull out the only file in the xml_files array
      xml_file_name = @xml_files.at(0)    
      
      # Define XML file naming convention and test for conformity
      regex_xml_file = Regexp.new('^' + "#{@unit_dir}" + '.xml$')
      if regex_xml_file.match(xml_file_name).nil?
        @error_messages.push("#{xml_file_name} does not match image naming convention.")
      end         

      # Read the XML file for processing
      doc = Nokogiri.XML(File.new(File.join(IN_PROCESS_DIR, @unit_dir, xml_file_name)))
      logger.debug "QaFilesystemAndIviewXmlProcessor: parsing XML file #{File.join(IN_PROCESS_DIR, @unit_dir, xml_file_name)}"

      # Check XML for expected elements
      root = doc.root  # "root" returns the root element, in this case <CatalogType>, not the document root preceding any elements
      unit = Unit.find @unit_id
      error_list = ImportIviewXml.qa_iview_xml(doc, unit)
      if error_list != []
        ( @error_messages << error_list ).flatten!
      end    
    
      # Make sure the number of <MediaItem> elements are equal to the number of TIF files on the filesystem
      mediaitem_count = root.xpath('MediaItemList/MediaItem').length
      if mediaitem_count != @number_content_files
        @error_messages.push("The number of <MediaItem> elements (#{mediaitem_count.to_i}) in the XML file is not equal to the number of TIF files on the filesystem (#{@number_content_files}).")
      end
      
      # Use Nokogiri to check XML entries at the <MediaItem> level
      root.xpath('MediaItemList/MediaItem').each {|mediaitem|
        filename = mediaitem.xpath('AssetProperties/Filename').text
        filesize = mediaitem.xpath('AssetProperties/FileSize').text 
        colorprofile = mediaitem.xpath('MediaProperties/ColorProfile').text
        headline = mediaitem.xpath('AnnotationFields/Headline').text

        filename_regexp = Regexp.new('^' + "#{@unit_dir}" + '_\d{4}.(tif|jp2)$')
   
        if not filename_regexp.match(filename)
          @error_messages.push("REGEXP: The <Filename> of <MediaItem> #{filename} does not pass regular expression test.")
          logger.debug "QaFilesystemAndIviewXmlProcessor RexExp was #{filename_regexp} and returned #{filename_regexp.match(filename)}"
        end

        if filesize == 0 or filesize.length == 0
          @error_messages.push("The <FileSize> of <MediaItem> #{filename} has a value of 0.")
        end

        # As of 3/2010, only two color profiles are used in production: Adobe RGB (1998) and cruse-lr-picto
        # 9/2010: In deference to the redelivery of RMDS material scanned under different procedures, Dot Gain 20% is now a legitimate color profile
        # 1/2014: Google Books tif/jp2 do not come with color profiles: grabbing ColorSpace a la Multispectral images
        if colorprofile != "Adobe RGB (1998)" and colorprofile != "cruse-lr-picto" and colorprofile != "Dot Gain 20%"
          # hack to compensate for Multispectral Scanner's lack of colorprofile data
          logger.debug "colorprofile is #{colorprofile}; colorspace is #{mediaitem.xpath('MediaProperties/ColorSpace').text}"
          logger.debug mediaitem.xpath('MediaProperties/ColorSpace').to_s
          if mediaitem.xpath('MediaProperties/ColorSpace').text.match(/(RGB|GREY|GRAY|BW)/)
            colorprofile = mediaitem.xpath('MediaProperties/ColorSpace').text.strip
          else
            @error_messages.push("194: The <ColorProfile> of <MediaItem> #{filename} is: #{colorprofile}.  This is not one of three accepted values: AdobeRGB (1998), Dot Gain 20% or cruse-lr-picto.")
          end
        end

        if headline =~ /^Page/
          @error_messages.push("The <Headline> of <MediaItem> #{filename} begins with 'Page': #{headline}")
        end
        if headline =~ /^p\./i
          @error_messages.push("The <Headline> of <MediaItem> #{filename} begins with 'p.': #{headline}")
        end
        if headline =~ /Endpaper/i && headline !~ /Front|Rear/i
          @error_messages.push("The <Headline> of <MediaItem> #{filename} is an endpaper but does not specify 'front' or 'rear' in conformance with metadata standards: #{headline}")
        end

        # Test to see if the <SetName> <Set> which contains this MasterFile <UniqueID> (if any), has a PID.  Fail if not.
        iview_id = mediaitem.xpath('AssetProperties/UniqueID').first.text
        node = root.xpath("//SetName/following-sibling::UniqueID[contains(., '#{iview_id}')]/preceding-sibling::SetName")
        if not node.empty?
          setname = root.xpath("//SetName/following-sibling::UniqueID[contains(., '#{iview_id}')]/preceding-sibling::SetName").last.text
          pid = setname[/pid=([-a-z]+:[0-9]+)/, 1]
          if pid.nil?
            @error_messages.push("Setname '#{setname}' does not contain a PID, therefore preventing assignment of Component to MasterFile")
          end
        end
      }

      # TODO: If unit.bibl.is_manuscript? there should be <SetName> that contain useful information
      # Check for <SetList> element
      if root.xpath('SetList/Set').empty?
        has_SetList = false
      else
        has_SetList = true
      end

      # Raise error if the Bibl record is a manuscript but there are no <SetList> elements or if it has <SetList> elements but is not a manuscript Bibl.  
      if @working_unit.bibl.is_manuscript?
        unless has_SetList == true
          @error_messages.push("Unit pertains to a manuscript, but XML has no <SetList> element.")
        end
      else
        if has_SetList == true
          # Determine whether <SetList> really contains anything meaningful
          set_count = root.xpath('SetList/Set').length
          set_name = root.xpath('SetList/Set/SetName').first
          if set_count == 1 and set_name and set_name.text == '@KeywordsSet'  # this strange value (some kind of placeholder?) occurs regularly in XML files created by iView; ignore it
            # not a meaningful SetList; ignore
          else
            @error_messages.push("Unit does NOT pertain to a manuscript, but XML has a <SetList> element.")
          end
        end
      end
    end
  end
  
  def check_ivc_files 
    # Checking for:
    # 1. Existence of a catalog
    # 2. That there is only one catalog
    # 3. That the catalog conforms to naming conventions.
    # 4. That the catalog is not an unacceptably small file.
    
    if @ivc_files.empty? == true
      @error_messages.push("There is no .ivc file in the directory.")
    elsif @ivc_files.length != 1
      # Check if there is more than one XML file in the directory
      @error_messages.push("There is more than one Iview catalog file in the directory.")
    else
      # If either of the two tests above fail, then the test below won't because there is no definitive file.
      ivc_file = @ivc_files.at(0)
      regex_ivc_file = Regexp.new('^' + "#{@unit_dir}" + '.ivc$')
      if regex_ivc_file.match(ivc_file).nil?
        @error_messages.push("#{ivc_file} does not match image naming convention.")
      end 
      
      if File.size(File.join(IN_PROCESS_DIR, @unit_dir, ivc_file)) < 4096
        @error_messages.push("#{ivc_file} is empty.")
      end
    end
  end
  
  def check_thumb_dir
    
  end
  
  def check_unknown_files
    if not @unknown_files.empty?
      logger.debug "QaFilesystemAndIviewXmlProcessor: check_unknown_files receiving list of #{@unknown_files.length} items"
      @unknown_files.each { |unknown_file| 
        if (unknown_file =~ /.TIF/ )
          @error_messages.push("#{unknown_file} ends in .TIF.")
        elsif (unknown_file =~ /.XML/ )
          @error_messages.push("#{unknown_file} ends in .XML.")
        elsif (unknown_file =~ /.IVC/ )
          @error_messages.push("#{unknown_file} ends in .IVC.")
        elsif (unknown_file =~ /.ivc_\d/ )
          @error_messages.push("#{unknown_file} is a resource fork of an Iview catalog.")
        elsif (unknown_file =~ /.jpg/)
          @error_messages.push("#{unknown_file} is a JPEG image.")
        else
          @error_messages.push("Contains unexpected or non-standard file: #{unknown_file}.")
        end
      }
    end
  end

  def handle_errors
    #-------------------------
    # Error Message Handling
    #-------------------------
    @error_messages.compact!
    if @error_messages.empty?
      path = File.join(IN_PROCESS_DIR, @unit_dir, @xml_files.at(0))
      message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :path => path })
      publish :import_unit_iview_xml, message
      on_success "Unit #{@unit_id} has passed the Filesystem and Iview XML QA Processor"
    else
      @error_messages.each {|message|
        logger.debug "QaFilesystemAndIviewXmlProcessor handle_errors >#{message.class}< >#{message.to_s}< "
        on_failure message
        if message == @error_messages.last
          on_error "Unit #{@unit_id} has failed the Filesystem and Iview XML QA Processor #{message.to_s}"
        end
      }
    end
  end
end
