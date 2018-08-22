class DropDirectoryNameFromContainerType < ActiveRecord::Migration[5.2]
   def up
      remove_column :container_types, :directory_name, :string
      c = ContainerType.find_by(name: "Flat File Drawer")
      if !c.nil?
         c.update(name: "Oversize Box")
      end
      c = ContainerType.find_by(name: "Tray")
      if !c.nil?
         c.update(name: "Flat File Drawer")
      end
      c = ContainerType.find_by(name: "Ledger")
      if !c.nil?
         c.update(name: "Bound Volume")
      end
      c = ContainerType.find_by(name: "Temporary Container")
      if !c.nil?
         c.update(name: "Temporary Location")
      end
   end

   def down
      add_column :container_types, :directory_name, :string
   end
end
