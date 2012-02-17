class UpgradeImageTechMeta < ActiveRecord::Migration
  def change
    change_table (:image_tech_meta, :bulk => true) do |t|
      t.change :aperture, :string
      t.change :color_profile, :string
      t.change :equipment, :string
      t.change :exposure_bias, :string
      t.change :exposure_time, :string
      t.change :model, :string
      t.change :software, :string
      t.change :exif_version, :string
      t.change :focal_length, :decimal, :precision => 10, :scale => 0
      t.change :master_file_id, :integer, :default => 0, :null => false
      t.remove :resolution_unit # All images use dpi as the resolution_unit, so there is no reason to keep this column
      t.remove_index :name => 'master_file_id'
      t.index :master_file_id
      t.foreign_key :master_files
    end
  end
end
