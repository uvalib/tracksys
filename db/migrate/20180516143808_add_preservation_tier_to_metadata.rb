class AddPreservationTierToMetadata < ActiveRecord::Migration[5.1]
  def change
     add_reference :metadata, :preservation_tier, index: true
  end
end
