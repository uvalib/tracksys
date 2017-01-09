# An ITEM is an ordered set of pages (master files).
# It is used as a method to connect tracksys to external metadata systems
# such as ArchivesSpace
#
class Item < ActiveRecord::Base
   has_many :master_files
   belongs_to :metadata

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
