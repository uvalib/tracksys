class RemoveUnsedFieldsFromMasterFile < ActiveRecord::Migration
  def change
     remove_column :master_files, :rels_ext, :text
     remove_column :master_files, :rels_int, :text
     remove_column :master_files, :dc, :text
     remove_column :master_files, :solr, :text
  end
end
