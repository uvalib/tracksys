class AddDplaToBibls < ActiveRecord::Migration
  def change
    add_column :bibls, :dpla, :boolean
  end
end
