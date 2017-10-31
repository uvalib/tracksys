class Location < ApplicationRecord
   belongs_to :container_type
   has_many :master_file_locations
   has_many :master_files, through: :master_file_locations

   validates :folder_id, :container_type, :container_id, presence: true
end
