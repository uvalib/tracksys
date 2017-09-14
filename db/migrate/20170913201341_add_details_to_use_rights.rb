class AddDetailsToUseRights < ActiveRecord::Migration[5.1]
  def change
     add_column :use_rights, :statement, :text
     add_column :use_rights, :commercial_use, :boolean, default: false
     add_column :use_rights, :educational_use, :boolean, default: false
     add_column :use_rights, :modifications, :boolean, default: false
  end
end
