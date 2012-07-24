class AddFieldsToComponents < ActiveRecord::Migration
  def change
  	change_table(:components, :bulk => true) do |t|
      t.integer :followed_by_id
      t.index :followed_by_id
      t.text :legacy_ead
      t.text :physical_desc
  	end
  end
end
