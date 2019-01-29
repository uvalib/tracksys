class MetadataVersion < ApplicationRecord
   belongs_to :metadata 
   belongs_to :staff_member

   validates :metadata, :presence => true
   validates :staff_member, :presence => true
   validates :desc_metadata, :presence => true
   validates :version_tag, :presence => true

   before_validation :set_version_tag, on: :create

   def set_version_tag 
      self.version_tag = SecureRandom.uuid
   end
end
