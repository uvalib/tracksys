class DropContainers < ActiveRecord::Migration
   def up
      drop_table :components_containers if ActiveRecord::Base.connection.table_exists? 'components_containers'
      drop_table :containers if ActiveRecord::Base.connection.table_exists? 'containers'
      drop_table :container_types if ActiveRecord::Base.connection.table_exists? 'container_types'
   end

   def down
      # not reversable
   end
end
