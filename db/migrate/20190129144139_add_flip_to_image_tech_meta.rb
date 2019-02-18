class AddFlipToImageTechMeta < ActiveRecord::Migration[5.2]
  def change
    add_column :image_tech_meta, :flip_axis, :integer, default: 0, index: true # [ENUM 0=none, 1=flip Y, 2=flipX ]
  end
end
