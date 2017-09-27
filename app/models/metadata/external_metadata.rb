# == Schema Information
#
# Table name: metadata
#
#  id                     :integer          not null, primary key
#  is_approved            :boolean          default(FALSE), not null
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
#  exemplar               :string(255)
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
#  external_system        :string(255)
#  external_uri           :string(255)
#  supplemental_system    :string(255)
#  supplemental_uri       :string(255)
#  genre_id               :integer
#  resource_type_id       :integer
#

class ExternalMetadata < Metadata
   #------------------------------------------------------------------
   # Prevent setting data valid for other classes in the STI model
   validates :catalog_key, :presence=>false
   validates :barcode, :presence=>false
   validates :call_number, :presence=>false
   validates :desc_metadata, :presence=>false
   validates :external_system, presence: true

   def url_fragment
      return "external_metadata"
   end
end
