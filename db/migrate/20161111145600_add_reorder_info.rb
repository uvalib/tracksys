class AddReorderInfo < ActiveRecord::Migration
  def change
     add_column :units, :reorder, :boolean,  :default => false
     add_column :master_files, :original_mf_id, :integer
     add_index  :master_files, :original_mf_id
  end
end
