class UpgradeOrders < ActiveRecord::Migration
  def change
    change_table(:orders, :bulk => true) do |t|
      t.integer :units_count, :default => 0
      t.integer :automation_messages_count, :default => 0
      t.integer :invoices_count, :default => 0
      t.integer :master_files_count, :default => 0
      t.change :date_due, :date
      t.remove_index :name => 'dvd_delivery_location_id'
      t.index :dvd_delivery_location_id
      t.foreign_key :agencies
      t.foreign_key :customers
      t.foreign_key :dvd_delivery_locations
    end
  
    say "Consolidating order.staff_notes and order.status_notes into order.staff_notes"
    Order.where('status_notes is not null').each {|o|
      o.staff_notes.to_s << "  #{o.status_notes.to_s}"
      o.save
    }

    change_table(:orders, :bulk => true) do |t|
      t.remove :status_notes
    end
  end
end
