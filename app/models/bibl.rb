# == Schema Information
#
# Table name: bibls
#
#  id                        :integer         not null, primary key
#  availability_policy_id    :integer
#  parent_bibl_id            :integer         default(0), not null
#  date_external_update      :datetime
#  description               :string(255)
#  is_approved               :boolean         default(FALSE), not null
#  is_collection             :boolean         default(FALSE), not null
#  is_in_catalog             :boolean         default(FALSE), not null
#  is_manuscript             :boolean         default(FALSE), not null
#  is_personal_item          :boolean         default(FALSE), not null
#  automation_messages_count :integer         default(0)
#  orders_count              :integer         default(0)
#  units_count               :integer         default(0)
#  barcode                   :string(255)
#  call_number               :string(255)
#  catalog_id                :string(255)
#  citation                  :text
#  copy                      :integer
#  creator_name              :string(255)
#  creator_name_type         :string(255)
#  genre                     :string(255)
#  issue                     :string(255)
#  location                  :string(255)
#  resource_type             :string(255)
#  series_title              :string(255)
#  title                     :string(255)
#  title_control             :string(255)
#  volume                    :string(255)
#  year                      :string(255)
#  year_type                 :string(255)
#  dc                        :text
#  desc_metadata             :text
#  discoverability           :boolean         default(TRUE), not null
#  exemplar                  :string(255)
#  pid                       :string(255)
#  rels_ext                  :text
#  rels_int                  :text
#  solr                      :text(16777215)
#  date_ingested_into_dl     :datetime
#  created_at                :datetime
#  updated_at                :datetime
#

require "#{Hydraulics.models_dir}/bibl"

class Bibl
end
