class UpgradeDatabase < ActiveRecord::Migration
  def change
  	drop_table :deliverable
  	drop_table :datastream
  	drop_table :image_specs
  	drop_table :tasks
  	drop_table :vendors
  	drop_table :vendor_batches
  	drop_table :workstations

  	remove_column :units, :fasttrack
  	remove_colum :units, :vendor_batch_id
  	remove_column :units, :content_model_id

  	rename_column :master_files, :name_num, :title
  	rename_column :master_files, :staff_notes, :description
  end
end
