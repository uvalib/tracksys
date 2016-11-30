# == Schema Information
#
# Table name: metadata
#
#  id                     :integer          not null, primary key
#  is_approved            :boolean          default(FALSE), not null
#  is_personal_item       :boolean          default(FALSE), not null
#  resource_type          :string(255)
#  genre                  :string(255)
#  is_manuscript          :boolean          default(FALSE), not null
#  is_collection          :boolean          default(FALSE), not null
#  title                  :text(65535)
#  creator_name           :string(255)
#  catalog_key            :string(255)
#  barcode                :string(255)
#  call_number            :string(255)
#  pid                    :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  exemplar               :string(255)
#  parent_bibl_id         :integer          default(0), not null
#  desc_metadata          :text(65535)
#  discoverability        :boolean          default(TRUE)
#  indexing_scenario_id   :integer
#  date_dl_ingest         :datetime
#  date_dl_update         :datetime
#  units_count            :integer          default(0)
#  availability_policy_id :integer
#  use_right_id           :integer
#  dpla                   :boolean          default(FALSE)
#  collection_facet       :string(255)
#  type                   :string(255)      default("SirsiMetadata")
#  external_attributes    :text(65535)
#

require 'nokogiri'
require 'open-uri'

class XmlMetadata < Metadata

   # Validate XML against all schemas. Returns an array of errors
   #
   def self.validate( xml )
      doc = Nokogiri.XML( xml )
      errors = []
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
