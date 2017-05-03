# == Schema Information
#
# Table name: collection_facets
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CollectionFacet < ActiveRecord::Base
   validates :name, presence: true
   validates :name, uniqueness: true
end
