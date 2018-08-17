class AddContainerTypeToProject < ActiveRecord::Migration[5.2]
  def change
     add_reference :projects, :container_type, index: true
  end
end
