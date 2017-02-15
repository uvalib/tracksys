class Workstation < ActiveRecord::Base
   has_and_belongs_to_many :equipment, :join_table=>:workstation_equipment
end
