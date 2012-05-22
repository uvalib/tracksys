class AddContainerTypeIdToContainers < ActiveRecord::Migration
  def change
    add_column :containers, :container_type_id, :integer

  end
end
