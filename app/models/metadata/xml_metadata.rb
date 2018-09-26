# == Schema Information
#
# Table name: metadata
#
#  id                     :integer          not null, primary key
#  is_personal_item       :boolean          default(FALSE), not null
#  is_manuscript          :boolean          default(FALSE), not null
#  title                  :text(65535)
#  creator_name           :string(255)
#  catalog_key            :string(255)
#  barcode                :string(255)
#  call_number            :string(255)
#  pid                    :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  parent_metadata_id     :integer          default(0), not null
#  desc_metadata          :text(65535)
#  discoverability        :boolean          default(TRUE)
#  date_dl_ingest         :datetime
#  date_dl_update         :datetime
#  units_count            :integer          default(0)
#  availability_policy_id :integer
#  use_right_id           :integer
#  dpla                   :boolean          default(FALSE)
#  collection_facet       :string(255)
#  type                   :string(255)      default("SirsiMetadata")
#  external_uri           :string(255)
#  supplemental_uri       :string(255)
#  collection_id          :string(255)
#  ocr_hint_id            :integer
#  ocr_language_hint      :string(255)
#  use_right_rationale    :string(255)
#  creator_death_date     :integer
#  qdc_generated_at       :datetime
#  preservation_tier_id   :bigint(8)
#  external_system_id     :bigint(8)
#  supplemental_system_id :bigint(8)
#

require 'nokogiri'
require 'open-uri'

class XmlMetadata < Metadata

   # Prevent setting data valid for other classes in the STI model
   validates :catalog_key, presence: false
   validates :barcode, presence: false
   validates :call_number, presence: false
   validates :external_system, presence: false
   validates :external_uri, presence: false
   validates :use_right, presence: true

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
