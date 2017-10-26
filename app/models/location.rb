class Location < ApplicationRecord
   belongs_to :metadata
   has_many :master_file_locations
   has_many :master_files, through: :master_file_locations

   validates :folder, :metadata, presence: true

   delegate :box, to: :metadata, allow_nil: false, prefix: false
end
