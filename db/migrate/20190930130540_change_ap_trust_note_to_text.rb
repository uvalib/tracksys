class ChangeApTrustNoteToText < ActiveRecord::Migration[5.2]
   def up
      change_column :ap_trust_statuses, :note, :text
   end

   def down
      change_column :ap_trust_statuses, :note, :string
   end
end
