require "#{Hydraulics.models_dir}/unit"

class Unit
  # Override Hydraulics Unit.overdue_materials and Unit.checkedout_materials scopes becuase our data should only concern itself 
  # with those materials checkedout a few months before Tracksys 3 goes live (i.e. before March 1st?)
  scope :overdue_materials, where("date_materials_received IS NOT NULL AND date_archived IS NOT NULL AND date_materials_returned IS NULL").where('date_materials_received >= "2012-03-01"')
  scope :checkedout_materials, where("date_materials_received IS NOT NULL AND date_materials_returned IS NULL").where('date_materials_received >= "2012-03-01"')

  after_update :fix_updated_counters
end
