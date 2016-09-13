# == Schema Information
#
# Table name: items
#
#  id           :integer          not null, primary key
#  pid          :string(255)
#  external_uri :string(255)
#  unit_id      :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

# An ITEM is an ordered set of pages (master files).
# It is used as a method to connect tracksys to external metadata systems
# such as ArchivesSpace
#
class Item < ActiveRecord::Base
   belongs_to :unit
   has_many :master_files
   has_one :metadata, :through => :unit

   # An item can be related to at most one component.
   # If it is, all masterfile will have a reference to it. Just
   # grab the first master file and return its component
   #
   def component
      return self.master_files.first.component
   end

   # Make sure the object has a valid pid
   #
   after_create do
      update_attribute(:pid, "tsi:#{self.id}")
   end
end
