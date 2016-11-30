class DropTechMetaTypeFromMasterFile < ActiveRecord::Migration
  def change
     remove_column  :master_files, :tech_meta_type, :string
  end
end
