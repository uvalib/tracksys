class AddDetailsToContainerType < ActiveRecord::Migration[5.2]
  def up
     add_column :container_types, :directory_name, :string
     add_column :container_types, :has_folders, :boolean, default: false

     c = ContainerType.find_by(name: "Oversize Box")
     if !c.nil?
       c.update(name: "Flat File Drawer")
     end

     ContainerType.find_by(name: "Box").update(directory_name: "box", has_folders: true)
     ContainerType.find_by(name: "Flat File Drawer").update(directory_name: "oversize", has_folders: true)
     ContainerType.find_by(name: "Tray").update(directory_name: "tray", has_folders: true)
     ContainerType.find_by(name: "Ledger").update(directory_name: "ledger", has_folders: false)
     ContainerType.create(name: "Temporary Container", directory_name: "temp", has_folders: false)
  end

  def down
     remove_column :container_types, :directory_name, :string
     remove_column :container_types, :has_folders, :boolean, default: false
  end
end
