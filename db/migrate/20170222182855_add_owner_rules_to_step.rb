class AddOwnerRulesToStep < ActiveRecord::Migration
  def change
     add_column :steps, :owner_type, :integer, default: 0  # enum owner_type: [:none, :prior, :unique, :original, :supervisor]
     remove_column :steps, :propagate_owner, :boolean
  end
end
