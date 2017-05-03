class CreateEquipment < ActiveRecord::Migration
  def change
    create_table :equipment do |t|
      t.string :type
      t.string :name
      t.string :serial_number
      t.timestamps null: false
    end
  end
end
