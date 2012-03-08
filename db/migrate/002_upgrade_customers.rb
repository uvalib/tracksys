class UpgradeCustomers < ActiveRecord::Migration
  def change

    Customer.all.each {|c|
      c.build_primary_address(:address_1 => c.address_1.to_s, :address_2 => c.address_2.to_s, :city => c.city.to_s, :state => c.state.to_s, :country => c.country, :post_code => c.post_code.to_s, :phone => c.phone.to_s, :organization => c.organization.to_s)

      if c.billing_address
        c.build_billing_address(:address_1 => c.billing_address.address_1.to_s, :address_2 => c.billing_address.address_2.to_s, :city => c.billing_address.city.to_s, :state => c.billing_address.state.to_s, :country => c.billing_address.country, :post_code => c.billing_address.post_code.to_s, :phone => c.billing_address.phone.to_s, :organization => c.billing_address.organization.to_s)
      end
      c.save!
    } 

    change_table(:customers, :bulk => true) do |t|
      t.integer :master_files_count, :default => 0
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
