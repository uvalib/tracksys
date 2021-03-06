require 'nokogiri'
require 'open-uri'

class XmlMetadata < Metadata
   include Publishable

   # Prevent setting data valid for other classes in the STI model
   validates :catalog_key, presence: false
   validates :barcode, presence: false
   validates :call_number, presence: false
   validates :external_system, presence: false
   validates :external_uri, presence: false
   validates :use_right, presence: true
   validates :desc_metadata, presence: true

   has_many :metadata_versions, :foreign_key => "metadata_id"

   before_save do
      if self.title.blank? || self.creator_name.blank?
         xml = Nokogiri::XML( self.desc_metadata )
         xml.remove_namespaces!
         if self.title.blank?
            title_node = xml.xpath( "//titleInfo/title" ).first
            self.title = title_node.text.strip if !title_node.nil?
         end
         if self.creator_name.blank?
            creator_node = xml.xpath("//name/namePart").first
            self.creator_name = creator_node.text.strip if !creator_node.nil?
         end
      end
   end

   def has_versions?
      return self.metadata_versions.count > 0
   end

   def personal_item?
      return self.is_personal_item
   end

   def url_fragment
      return "xml_metadata"
   end

   # Validate XML against all schemas. Returns an array of errors
   #
   def self.validate( xml )
      doc = Nokogiri.XML( xml )
      errors = []
      doc.errors.each do |e|
         errors << e.message
      end
      if errors.length > 0
         return errors
      end

      if doc.root.nil?
         errors << "XML data is required"
         return errors
      end

      # schemas are held in the root; iterate over all included
      schema_info = doc.root.each do |schema_info|

         # split int a has of nameapace and URI. Only care about URI
         schemata_by_ns = Hash[ schema_info.last.scan(/(\S+)\s+(\S+)/)]
         schemata_by_ns.each do |ns,xsd_uri|
            # Validate against URI and track any errors that occur
            xsd = Nokogiri::XML.Schema(open(xsd_uri))
            xsd.validate(doc).each do |error|
               errors << "Line #{error.line} - #{error.message}"
            end
         end
      end

      return errors
   end
end
