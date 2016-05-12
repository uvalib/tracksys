class UpdateUseRights < ActiveRecord::Migration
   def up
      remove_foreign_key :units, :use_right
      remove_column :units, :use_right_id
      remove_foreign_key :components, :use_right
      remove_column :components, :use_right_id
      remove_column :use_rights, :components_count
      remove_column :use_rights, :units_count
      remove_column :use_rights, :description
   end

   def down
      add_column :use_rights, :components_count, :integer, :default=>0
      add_column :use_rights, :units_count, :integer, :default=>0
      add_column :use_rights, :description, :string
      add_reference :units, :use_rights, index: true
      add_reference :components, :use_rights, index: true
   end
end
