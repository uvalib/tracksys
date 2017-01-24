class Step < ActiveRecord::Base
   validates :name, :presence => true
   validates :sequence, :presence=>true
   belongs_to :workflow

   default_scope { order(sequence: :asc) }
end
