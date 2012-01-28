class UpgradeComponents < ActiveRecord::Migration
  def change
    # All images use dpi as the resolution_unit, so there is no reason to keep this column
    remove_column :image_tech_meta, :resolution_unit
  end
end
