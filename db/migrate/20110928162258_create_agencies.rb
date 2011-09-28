class CreateAgencies < ActiveRecord::Migration
  def change
    create_table :agencies do |t|
      t.string :name
      t.string :description
      t.boolean :is_billable, :null => false, :default => 0  # boolean values should be 0 or 1 (disallow NULL)
      t.string :last_name
      t.string :first_name
      t.string :address_1
      t.string :address_2
      t.string :city
      t.string :state
      t.string :country
      t.string :post_code
      t.string :phone
      t.integer :orders_count, :default => 0

      t.timestamps
    end
    
    add_index :agencies, :name, :unique => true
  end
end