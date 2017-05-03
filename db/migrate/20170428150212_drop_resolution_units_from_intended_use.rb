class DropResolutionUnitsFromIntendedUse < ActiveRecord::Migration
  def change
     remove_column :intended_uses, :deliverable_resolution_unit, :integer
  end
end
