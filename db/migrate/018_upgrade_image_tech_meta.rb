class UpgradeImageTechMeta < ActiveRecord::Migration
  def change
    change_column :image_tech_meta, :aperture, :string
    change_column :image_tech_meta, :color_profile, :string
    change_column :image_tech_meta, :equipment, :string
    change_column :image_tech_meta, :exposure_bias, :string
    change_column :image_tech_meta, :exposure_time, :string
    change_column :image_tech_meta, :model, :string
    change_column :image_tech_meta, :software, :string
    change_column :image_tech_meta, :exif_version, :string
    change_column :image_tech_meta, :focal_length, :decimal, :precision => 10, :scale => 0
    change_column :image_tech_meta, :master_file_id, :integer, :default => 0, :null => false

    # All images use dpi as the resolution_unit, so there is no reason to keep this column
    remove_column :image_tech_meta, :resolution_unit

    rename_index :image_tech_meta, 'master_file_id', 'index_image_tech_meta_on_master_file_id'
    
    add_foreign_key :image_tech_meta, :master_files   
  end
end
