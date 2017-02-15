class CreateWorkstations < ActiveRecord::Migration
   def change
      create_table :workstations do |t|
         t.string :name
         t.timestamps null: false
      end

      create_table :workstation_equipment do |t|
         t.references :workstation, index: true
         t.references :equipment, index: true
         t.timestamps
      end
   end
end
