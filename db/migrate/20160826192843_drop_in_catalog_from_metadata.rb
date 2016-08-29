class DropInCatalogFromMetadata < ActiveRecord::Migration
  def change
      remove_column :metadata, :is_in_catalog, :boolean
      remove_column :units, :exclude_from_dl, :boolean
  end
end
