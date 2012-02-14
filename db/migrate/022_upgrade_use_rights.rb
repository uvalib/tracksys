class UpgradeUseRights < ActiveRecord::Migration

  def change
    add_column :use_rights, :bibls_count, :integer, :default => 0
    add_column :use_rights, :components_count, :integer, :default => 0
    add_column :use_rights, :master_files_count, :integer, :default => 0
  end
end