module ExportIviewXML

# given a guide (Component), build an XML file suitable for editing in Expressions (iView) Media
	def create_iview_xml(arg = nil)
	  arg ||= self
	  # check what we've been given before proceeding
	  case arg
	  when Component
	    @component = arg
	  when Fixnum
	    @component = Component.find(arg)
	  else raise ArgumentError "#{__method__} expects a Component or Component.id as first argument!"
	  end
	  @guide = nil
	  # build guide from top-level component
	  if @component.respond_to?(:ancestor_ids)
	    then @guide = @component.root
      else raise ArgumentError, "Component #{@component.id} must respond to :ancestor_ids"
    end
    raise ArgumentError, "" unless @guide.is_a?(Component)
	  # load a template xml file, containing only <Catalog> and 1 child <MediaItemList> with sample JPEG
	  @template = <<-EOXML
	  <?expression media exportversion="1.0" appversion="1.0"?>
	  <CatalogType>
	   <Catalog pathType="MAC">EAD__Catalog</Catalog>
	   <MediaItemList><!-- *** DELETE THE MediaItem ELEMENT FOR doNotTouch.jpg! *** --><MediaItem>
	         <AssetProperties>
	            <Filename>doNotTouch.jpg</Filename>
	            <Filepath>digiserv-production:administrative:doNotTouch:doNotTouch.jpg</Filepath>
	            <UniqueID>1</UniqueID>
	            <Label>0</Label>
	            <Rating>0</Rating>
	            <MediaType>JPEG</MediaType>
	            <FileSize unit="Bytes">36243</FileSize>
	            <Created>2009:06:04 15:07:22</Created>
	            <Modified>2009:06:04 15:07:22</Modified>
	            <Added>2009:06:18 13:29:03</Added>
	            <Annotated>2009:06:18 13:29:10</Annotated>
	         </AssetProperties>
	         <MediaProperties>
	            <Width unit="Pixels">99</Width>
	            <Height unit="Pixels">640</Height>
	            <Resolution unit="DPI">72</Resolution>
	            <Depth unit="Bits">24</Depth>
	            <ViewRotation>1</ViewRotation>
	            <SampleColor>R:30 G:30 B:F0</SampleColor>
	            <Pages>1</Pages>
	            <ColorSpace>RGB </ColorSpace>
	            <Compression>65541</Compression>
	            <PrimaryEncoding>Photo - JPEG</PrimaryEncoding>
	            <ColorProfile/>
	         </MediaProperties>
	         <MetaDataFields>
	            <SourceURL/>
	         </MetaDataFields>
	      </MediaItem>
	   </MediaItemList>
	   <SetList/>
	  </CatalogType>
	EOXML
	
	  @doc=Nokogiri::XML( @template ) { |config| config.noblanks }
	  @doc.encoding="UTF-8"
	  
	  # change the text content of <CatalogType><Catalog> to "EAD_" + guideId + "_Catalog"
	  @doc.xpath("/CatalogType/Catalog").first.content="Component_#{@component.id}_#{@component.ead_id_att}_Catalog"
	  # add a new <Set> and recurse downwards from guide, adding metadata in <SetName> child
	  fragment=@doc.xpath("/CatalogType/SetList").first.add_child(Nokogiri::XML::Node.new "Set", @doc)
	  #add_component_data( @component, fragment )
	  #add_ead_data( ead, fragment ) # test only
	  # dump to file
	  #File.open("/tmp/test.xml", 'w') {|f| f.puts @doc.to_xml(:indent => 2)}
	  
	  case @guide
	  when Component
	    add_component_data(@guide, fragment)
	  end
	  #return @doc
		filename= @guide.name.parameterize.underscore.truncate(255)
		@file=File.open("#{IVIEW_CATALOG_EXPORT_DIR}/#{filename}.xml", 'w') 
		logger.debug "writing file to #{IVIEW_CATALOG_EXPORT_DIR}/#{filename}.xml"
		@file << @doc
		@file.close
	end
	
	def add_component_data(component, xmlfragment)
	  # ensure xmlfragment's root node is a <Set> element
	  raise ArgumentError "arg2 should be a <Set> element" unless xmlfragment.name == "Set"
	
	  # build SetName and attributes
	  # metadata is: type=ead ~ level={@level} ~ id={@id} ~ date={date str} ~ desc={description}
	  data_str="level=#{component.level} ~ ComponentId=#{component.id} ~ pid=#{component.pid} ~ date=#{component.date} ~ desc=#{component.content_desc}"
	  
	  # make a new <SetName> for this object
	  set_name = xmlfragment.add_child(Nokogiri::XML::Node.new("SetName", @doc))
	  set_name.content=data_str
	  
	  # for each child Component, make a new <Set> and send it and the child to yourself
	  fragment=xmlfragment.add_child(Nokogiri::XML::Node.new "Set", @doc) unless component.children.empty?
	  component.children.each { |c| add_component_data(c, fragment) }
	  return true
	end

end
