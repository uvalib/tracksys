class ConvertFlipAxisToOrientation < ActiveRecord::Migration[5.2]
  def change
    remove_column  :image_tech_meta, :flip_axis, :integer, default: 0, index: true # [ENUM 0=none, 1=flip Y, 2=flipX ]
    
    # [ENUM 0=normal, 1=flip Y, 2=rotate90, 3=rotate180, 4=rotate270 ]
    add_column :image_tech_meta, :orientation, :integer, default: 0, index: true 
  end
end
