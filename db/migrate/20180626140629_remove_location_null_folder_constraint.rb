class RemoveLocationNullFolderConstraint < ActiveRecord::Migration[5.2]
  def change
     change_column_null :locations, :folder_id, true
     if ContainerType.find_by(name: "Ledger").nil?
        ContainerType.create(name: "Ledger")
     end
  end
end
