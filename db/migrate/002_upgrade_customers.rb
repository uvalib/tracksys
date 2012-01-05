class UpgradeCustomers < ActiveRecord::Migration
  def change
    remove_index :customers, :column => :uva_status_id

    rename_column :customers, :uva_status_id, :academic_status_id
    
    add_index :customers, :academic_status_id
    rename_index :customers, 'department_id', 'index_customers_on_department_id'
    rename_index :customers, 'heard_about_service_id', 'index_customers_on_heard_about_service_id'

    add_column :customers, :orders_count, :integer, :default => 0
    add_column :customers, :units_count, :integer, :default => 0
    add_column :customers, :master_files_count, :integer, :default => 0
    
    say "Updating customer.orders_count, customer.units_count and customer.master_files_count"
    Customer.find(:all).each {|c|
      Customer.update_counters c.id, :orders_count => c.orders.count
      Customer.update_counters c.id, :units_count => c.units.count
      Customer.update_counters c.id, :master_files_count => c.master_files.count
    }

    add_foreign_key :customers, :academic_statuses
    add_foreign_key :customers, :departments
    add_foreign_key :customers, :heard_about_services
  end
end
