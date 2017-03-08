class Equipment < ActiveRecord::Base
   enum status: [:active, :inactive, :retired]
   validates :status, presence: true
   validates :name, presence: true
   validates :serial_number, presence: true, uniqueness: true
   default_scope { order(type: :asc) }

   def workstation
      Workstation.joins("inner join workstation_equipment e on e.workstation_id = workstations.id").where("e.equipment_id=?", id).first
   end
end
