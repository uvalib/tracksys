class AddDeliverableInformationToIntendedUses < ActiveRecord::Migration
  def change
    add_column :intended_uses, :deliverable_format, :string
    add_column :intended_uses, :deliverable_resolution, :string
    add_column :intended_uses, :deliverable_resolution_unit, :string
  end
end
