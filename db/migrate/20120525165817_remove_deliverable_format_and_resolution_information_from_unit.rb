class RemoveDeliverableFormatAndResolutionInformationFromUnit < ActiveRecord::Migration
  def change
    remove_column :units, :deliverable_format
    remove_column :units, :deliverable_resolution
    remove_column :units, :deliverable_resolution_unit
  end
end
