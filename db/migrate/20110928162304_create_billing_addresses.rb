class CreateBillingAddresses < ActiveRecord::Migration
  def change
    create_table :billing_addresses do |t|
      t.integer :customer_id
      t.integer :agency_id
      t.string :last_name
      t.string :first_name
      t.string :address_1
      t.string :address_2
      t.string :city
      t.string :state
      t.string :country
      t.string :post_code
      t.string :phone
      t.string :organization

      t.timestamps
    end
    add_index :billing_addresses, :customer_id, :unique => true
    add_index :billing_addresses, :agency_id, :unique => true
  end
end