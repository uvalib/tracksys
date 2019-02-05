class QaFilesystemAndIviewXml < BaseJob
   require 'nokogiri'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      # Set unit variables
      @unit = Unit.find(message[:unit_id])
      @unit_dir = "%09d" % @unit.id
      @in_proc_dir = Finder.finalization_dir(@unit, :in_process)

      # Create error message holder array
      @error_messages = Array.new

      # Create a series of arrays to hold the files contained within the entry directory so that each type
      # of expected and unexpected files can be tested for compliance.
      @content_files = Array.new
      @xml_files = Array.new
      @ivc_files = Array.new
      @unknown_files = Array.new

      # recurse through all files/directories in the unit inprocess directory
      # NOTE: the final step of the project automation ensures that no garbage files
      # get through to this stage. Most of the original filtering code that was
      # present here is no longer needed (see Step::validate_last_step_dir )
      Dir.glob(File.join(@in_proc_dir, "**/*")).each do |dir_entry|
         next if File.directory? dir_entry  # skip the directory names
         if (dir_entry =~ /.tif$/)
            @content_files.push(dir_entry)
         elsif (dir_entry =~ /.xml$/)
            @xml_files.push(dir_entry)
         elsif (dir_entry =~ /.(ivc|mpcatalog)$/)
            @ivc_files.push(dir_entry)
         elsif (dir_entry !~ /.txt$/)    # safe to ignore (.txt files are OCR data typically)
            @unknown_files.push(dir_entry)
         end
      end

      if @ivc_files.count == 0
         logger.info "No iview/mpcatalog files present; doing raw import"
         fatal_error("There are no .tif files in the directory.") if @content_files.empty?
         fatal_error("Unknown files in the directory: #{@unknown_files.join(',')}") if not @unknown_files.empty?
         fatal_error("XML file count does not match tif count") if @xml_files.count > 0 && @xml_files.count != @content_files.count
         ImportRawImages.exec_now({ :unit => @unit, :images=>@content_files, :xml_files=>@xml_files }, self)
      else
         #NOTE: when using the .glob call above, all files in the lists will be FULL PATH
         check_content_files
         check_xml_files
         check_ivc_files
         check_unknown_files
         handle_errors
      end
   end

   def check_content_files
      logger.info "Check content files..."
      # Checking for:
      # 1. Existence of TIF files.
      # 2. The number of content files in the directory equals the sequence number of the last file.
      # 3. All TIF files conform to the naming convention.
      # 4. No file is less than 1MB (1MB being a size arbitrarily determined to represent a "too small" file)
      minimum_size=2048

      if @content_files.empty?
         @error_messages.push("There are no .tif files in the directory.")
         return
      end

      # Check that the number of .tif files in the entry directory equals the sequence number of the last file
      @content_files.sort!
      @number_content_files = @content_files.length

      # Define regex to ensure the file ends with an _, followed by four digits followed by .tif
      regex_content_file = Regexp.new('_\d{4}.(tif)$')

      max_sequence_num = -1
      max_seq_file = ""
      @content_files.each do |content_file_path|
         content_file = File.basename(content_file_path)

         # extract the sequence num from the name: unit_SEQ.tif
         seq = content_file.split("_")[1].split(".")[0].to_i
         if seq > max_sequence_num
            max_sequence_num = seq
            max_seq_file = content_file
         end

         # Check that the content file begins with the unit number
         if content_file !~ /^#{@unit_dir}/
            @error_messages.push("#{content_file} does not start with the correct unit #{@unit_dir}")
         end
         # Check the file part of the tif file
         if regex_content_file.match(content_file).nil?
            @error_messages.push("#{content_file} has an incorrectly formatted sequence number or extension.")
         end
         # Check that the content file is greater than 1MB.
         if File.size(content_file_path) < minimum_size
            @error_messages.push("#{content_file} is less than #{minimum_size} bytes large and is very likely an incorrect file.")
         end
      end

      if max_sequence_num > @number_content_files
         @error_messages.push("The number of tif files in directory (#{@number_content_files}) does not equal the sequence number of the last file (#{max_seq_file}).")
      end
   end

   def check_xml_files
      logger.info "Check XML files..."
      # Checking for:
      # 1. Existence of a XML file
      # 2. That there is only one XML file
      # 3. That the XML file conforms to naming conventions.

      if @xml_files.empty?
         @error_messages.push("There is no .xml file in the directory.")
         return
      end

      if @xml_files.length > 1
         @error_messages.push("There is more than one xml file in the directory.")
         return
      end

      # Pull out the only file in the xml_files array
      xml_file_path = @xml_files.at(0)
      xml_file_name = File.basename(xml_file_path)

      # Define XML file naming convention and test for conformity
      regex_xml_file = Regexp.new('^' + "#{@unit_dir}" + '.xml$')
      if regex_xml_file.match(xml_file_name).nil?
         @error_messages.push("#{xml_file_name} does not match image naming convention.")
      end

      # Read the XML file for processing
      logger().debug "Parsing XML file #{xml_file_path}"
      doc = Nokogiri.XML( File.open(xml_file_path) )

      # Check XML for expected elements
      root = doc.root  # "root" returns the root element, in this case <CatalogType>, not the document root preceding any elements
      error_list = ImportIviewXml.qa_iview_xml(doc, @unit )
      if !error_list.nil?
         ( @error_messages << error_list ).flatten!
      end

      # Make sure the number of <MediaItem> elements are equal to the number of TIF files on the filesystem
      mediaitem_count = root.xpath('MediaItemList/MediaItem').length
      if mediaitem_count != @number_content_files
         @error_messages.push("The number of <MediaItem> elements (#{mediaitem_count.to_i}) in the XML file is not equal to the number of TIF files on the filesystem (#{@number_content_files}).")
      end

      # Use Nokogiri to check XML entries at the <MediaItem> level
      root.xpath('MediaItemList/MediaItem').each do |mediaitem|
         filename = mediaitem.xpath('AssetProperties/Filename').text
         filesize = mediaitem.xpath('AssetProperties/FileSize').text
         colorprofile = mediaitem.xpath('MediaProperties/ColorProfile').text
         headline = mediaitem.xpath('AnnotationFields/Headline').text

         filename_regexp = Regexp.new('^' + "#{@unit_dir}" + '_\d{4}.(tif|jp2)$')

         if not filename_regexp.match(filename)
            @error_messages.push("REGEXP: The <Filename> of <MediaItem> #{filename} does not pass regular expression test.")
            logger().debug "RexExp was #{filename_regexp} and returned #{filename_regexp.match(filename)}"
         end

         if filesize == 0 or filesize.length == 0
            @error_messages.push("The <FileSize> of <MediaItem> #{filename} has a value of 0.")
         end

         # As of 3/2010, only two color profiles are used in production: Adobe RGB (1998) and cruse-lr-picto
         # 9/2010: In deference to the redelivery of RMDS material scanned under different procedures, Dot Gain 20% is now a legitimate color profile
         # 1/2014: Google Books tif/jp2 do not come with color profiles: grabbing ColorSpace a la Multispectral images
         if colorprofile != "Adobe RGB (1998)" and colorprofile != "cruse-lr-picto" and colorprofile != "Dot Gain 20%"
            # hack to compensate for Multispectral Scanner's lack of colorprofile data
            logger().debug "colorprofile is #{colorprofile}; colorspace is #{mediaitem.xpath('MediaProperties/ColorSpace').text}"
            logger().debug mediaitem.xpath('MediaProperties/ColorSpace').to_s
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
      end
   end

   def check_ivc_files
      logger.info "Check .mpcatalog files..."
      # Checking for:
      # 1. Existence of a catalog
      # 2. That there is only one catalog
      # 3. That the catalog conforms to naming conventions.
      # 4. That the catalog is not an unacceptably small file.

      if @ivc_files.empty? == true
         @error_messages.push("There is no .ivc file in the directory.")
      elsif @ivc_files.length > 1
         # Check if there is more than one XML file in the directory
         @error_messages.push("There is more than one Iview catalog file in the directory.")
      else
         # If either of the two tests above fail, then the test below won't because there is no definitive file.
         ivc_path = @ivc_files.at(0)
         ivc_file = File.basename(ivc_path)
         regex_ivc_file = Regexp.new('^' + "#{@unit_dir}" + '.(ivc|mpcatalog)$')
         if regex_ivc_file.match(ivc_file).nil?
            @error_messages.push("#{ivc_file} does not match image naming convention.")
         end

         if File.size(ivc_path) < 4096
            @error_messages.push("#{ivc_file} is empty.")
         end
      end
   end

   def check_unknown_files
      logger.info "Check unknown files..."
      @unknown_files.each do |unknown_file|
         @error_messages.push("Contains unexpected or non-standard file: #{File.basename(unknown_file)}.")
      end
   end

   def handle_errors
      logger.info "Handle Errors: [#{@error_messages.join(', ')}]"
      if @error_messages.empty?
         on_success "Unit #{@unit.id} has passed the Filesystem and Iview XML QA"
         ImportUnitIviewXML.exec_now({ :unit_id => @unit.id, :path => @xml_files.at(0) }, self)
      else
         @error_messages.each do |message|
            log_failure message
         end
         fatal_error "Unit #{@unit.id} has failed the Filesystem and IView XML QA."
      end
   end
end
