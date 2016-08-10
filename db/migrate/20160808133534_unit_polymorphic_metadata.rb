class UnitPolymorphicMetadata < ActiveRecord::Migration
   def up
      add_column :units, :metadata_type, :string, :default=>"SirsiMetadata"
      remove_foreign_key :units, :bibl
      rename_column :units, :bibl_id, :metadata_id

      add_index :units, [:metadata_type, :metadata_id]
   end

   def down
      remove_column :units, :metadata_type
      rename_column :units, :metadata_id, :bibl_id
   end
end
