class AddDateDeaccessionedToMasterFiles < ActiveRecord::Migration
  def change
     add_column :master_files, :deaccessioned_at, :datetime
     add_column :master_files, :deaccession_note, :text
     add_column :master_files, :deaccessioned_by_id, :integer
  end
end
