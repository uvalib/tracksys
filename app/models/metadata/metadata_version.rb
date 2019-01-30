class MetadataVersion < ApplicationRecord
   belongs_to :metadata 
   belongs_to :staff_member

   validates :metadata, :presence => true
   validates :staff_member, :presence => true
   validates :desc_metadata, :presence => true
   validates :version_tag, :presence => true, :uniqueness=>true
end
