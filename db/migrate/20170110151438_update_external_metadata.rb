class UpdateExternalMetadata < ActiveRecord::Migration
  def change
     remove_column  :metadata, :external_attributes, :text
     add_column  :metadata, :external_system, :string
     add_column  :metadata, :external_uri, :string
     add_column  :metadata, :supplemental_system, :string
     add_column  :metadata, :supplemental_uri, :string
  end
end
