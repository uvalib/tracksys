class CreatePreservationTier < ActiveRecord::Migration[5.1]
  def up
    create_table :preservation_tiers do |t|
      t.string :name
      t.string :description
    end
    
    # add_reference :metadata, :preservation_tier, index: true
    PreservationTier.create([
      {name: "Tier 1", description: "Backed-up"},
      {name: "Tier 2", description: "Duplicated in separate physical location"},
      {name: "Tier 3", description: "Multiple storage technologies, multiple geographic regions"}
    ])
  end

  def down
     remove_reference :metadata, :preservation_tier, index: true
     drop_table :preservation_tiers
  end
end
