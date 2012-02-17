class UpgradeCustomers < ActiveRecord::Migration
  def change
    change_table(:customers, :bulk => true) do |t|
      t.remove_index :uva_status_id
      t.rename :uva_status_id, :academic_status_id
      t.index :academic_status_id
      t.remove_index :name => 'department_id'
      t.remove_index :name => 'heard_about_service_id'
      t.index :department_id
      t.index :heard_about_service_id
      t.column :orders_count, :integer, :default => 0
      t.foreign_key :academic_statuses
      t.foreign_key :departments
      t.foreign_key :heard_about_services
    end
  end
end
