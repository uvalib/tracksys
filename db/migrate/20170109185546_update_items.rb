class UpdateItems < ActiveRecord::Migration
  def change
     remove_column  :items, :external_uri, :string
     remove_reference  :items, :unit, index: true
     add_column :items, :external_system, :string
     add_column :items, :external_id, :string
     add_reference :items, :metadata, index: true
  end
end
