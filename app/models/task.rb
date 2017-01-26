class Task < ActiveRecord::Base
   enum condition: [:good, :bad]
   enum category: [:book, :manuscript, :slide, :cruse_scan]

   belongs_to :workflow
   belongs_to :unit
   
   validates :workflow,  :presence => true
   validates :unit,  :presence => true
   validates :added_on,  :presence => true
   validates :due_on,  :presence => true
end
