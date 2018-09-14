# == Schema Information
#
# Table name: workstations
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  status     :integer          default("active")
#

class Workstation < ApplicationRecord
   enum status: [:active, :inactive, :retired]
   has_many :projects
   has_and_belongs_to_many :equipment, :join_table=>:workstation_equipment

   # non-retired, sorted by name
   default_scope { where("status <> 2").order(name: :asc) }

   def active_project_count
      return projects.active.count
   end

   def available?
      return false if !active?
      return equipment_ready?
   end

   def equipment_ready?
      return false if equipment.count == 0
      equipment.each do |e|
         return false if !e.active?
      end
      return true
   end

   def self.available
      Workstation.joins("inner join workstation_equipment e on workstations.id=e.workstation_id").where("status=0").distinct("workstations.id")
   end
end
