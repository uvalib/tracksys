class Equipment < ApplicationRecord
   enum status: [:active, :inactive, :retired]
   validates :status, presence: true
   validates :name, presence: true
   validates :type, presence: true
   validates :serial_number, presence: true, uniqueness: true
   default_scope { where("status <> 2").order(type: :asc).order(name: :asc) }

   def workstation
      Workstation.joins("inner join workstation_equipment e on e.workstation_id = workstations.id").where("e.equipment_id=?", id).first
   end
end
