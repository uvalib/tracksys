class AddBiblsCountToIndexDestinations < ActiveRecord::Migration
  def change
    add_column :index_destinations, :bibls_count, :integer
    add_column :index_destinations, :units_count, :integer
    add_column :index_destinations, :components_count, :integer
    add_column :bibls, :index_destination_id, :integer, null: true
    add_column :units, :index_destination_id, :integer, null: true
    add_column :components, :index_destination_id, :integer, null: true
  end
end
