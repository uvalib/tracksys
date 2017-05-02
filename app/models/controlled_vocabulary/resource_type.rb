class ResourceType < ActiveRecord::Base
   validates :name, presence: true
end
