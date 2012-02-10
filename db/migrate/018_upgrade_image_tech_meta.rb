class UpgradeImageTechMeta < ActiveRecord::Migration
  def change
    # All images use dpi as the resolution_unit, so there is no reason to keep this column
    remove_column :image_tech_meta, :resolution_unit
    
    add_foreign_key :image_tech_meta, :master_files
  end
end
