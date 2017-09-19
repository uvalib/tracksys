module ExportIviewXML

   # Build an XML file suitable for editing in Expressions (iView) Media from a component
   def create_iview_xml
      guide = self.root

      # load a template xml file, containing only <Catalog> and 1 child <MediaItemList> with sample JPEG
      template = <<-EOXML
      <?expression media exportversion="1.0" appversion="1.0"?>
      <CatalogType>
   	   <Catalog pathType="MAC">EAD__Catalog</Catalog>
         <MediaItemList><!-- *** DELETE THE MediaItem ELEMENT FOR doNotTouch.jpg! *** -->
            <MediaItem>
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

      doc=Nokogiri::XML( template ) { |config| config.noblanks }
      doc.encoding="UTF-8"

      # change the text content of <CatalogType><Catalog> to "EAD_" + guideId + "_Catalog"
      doc.xpath("/CatalogType/Catalog").first.content="Component_#{guide.id}_#{guide.ead_id_att}_Catalog"

      # add a new <Set> and recurse downwards from guide, adding metadata in <SetName> child
      fragment = doc.xpath("/CatalogType/SetList").first.add_child(Nokogiri::XML::Node.new "Set", doc)

      add_component_data(doc, guide, fragment)

      filename=String.new
      case guide.ead_id_att
      when /^viu/
         filename =  guide.ead_id_att
      else
         filename = guide.name.parameterize.underscore.truncate(255)
      end

      export_base = "#{Settings.production_mount}/administrative/EAD2iViewXML"
      export_filename = File.join(export_base, "#{filename}.xml")
      file = File.open(export_filename, 'w')
      logger.debug "writing file to #{export_filename}"
      file << doc
      file.close
   end

   def add_component_data(doc, component, xmlfragment)
      # build SetName and attributes
      # metadata is: type=ead ~ level={@level} ~ id={@id} ~ date={date str} ~ desc={description}
      data_str="level=#{format_component_strings(component.level)} ~ pid=#{component.pid} ~ date=#{format_component_strings(component.date)} ~ desc=#{format_component_strings(component.iview_description)}"

      # make a new <SetName> for this object
      set_name = xmlfragment.add_child(Nokogiri::XML::Node.new("SetName", doc))
      set_name.content=data_str

      # for each child Component, make a new <Set> and send it and the child to yourself
      fragment=xmlfragment.add_child(Nokogiri::XML::Node.new "Set", doc) unless component.children.empty?
      component.children.each { |c| add_component_data(doc, c, fragment) }
      return true
   end

   # Goals:
   # 1. Remove all newlines
   # 2. Remove all spaces
   # N.B. Given that incoming data from EAD guides cannot be trusted for legibility
   # all strings exported from this data, especially for ExportIviewXml module,
   # have to be stripped of their newlines and extraneous spaces
   #
   # 3. Remove all commas.  Iview/MS Expression Media does not do well with commas in
   # <SetName> values.  Since the contents of the title do not matter for export and
   # are only of consequence for student worker legibility, they can be removed.
   private
   def format_component_strings(string)
     begin
       return string.strip.gsub(/\n/, ' ').gsub(/  +/, ' ').gsub(/,/, '').gsub(/;/, '').truncate(100)
     rescue Exception => e
       return nil
     end
   end
end
