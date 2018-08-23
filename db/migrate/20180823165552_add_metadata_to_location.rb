class AddMetadataToLocation < ActiveRecord::Migration[5.2]
  def change
     add_reference :locations, :metadata, index: true
  end
end
