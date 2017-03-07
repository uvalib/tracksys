class Workstation < ActiveRecord::Base
   enum status: [:active, :maintenance, :retired]
   has_and_belongs_to_many :equipment, :join_table=>:workstation_equipment
   default_scope { where("status <> 2").order(name: :asc) }
end
