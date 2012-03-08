class UpgradeCustomers < ActiveRecord::Migration
  # Must create legacy BillingAddress class so that we can access the legacy information
  class BillingAddress < ActiveRecord::Base
  end

  def change

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

    # Build customer.primary_address
    Customer.all.each {|c|
      c.build_primary_address(:address_1 => c.address_1.to_s, :address_2 => c.address_2.to_s, :city => c.city.to_s, :state => c.state.to_s, :country => c.country, :post_code => c.post_code.to_s, :phone => c.phone.to_s, :organization => c.organization.to_s)
      c.save
    } 

    # Build Billing Address
    BillingAddress.all.each {|ba|
      if ba.customer_id
        c = Customer.find(ba.customer_id)
        c.build_billable_address(:address_1 => ba.address_1.to_s, :address_2 => ba.address_2.to_s, :city => ba.city.to_s, :state => ba.state.to_s, :country => ba.country, :post_code => ba.post_code.to_s, :phone => ba.phone.to_s, :organization => ba.organization.to_s)
        c.save
      end
    }

    change_table(:customers, :bulk => true) do |t|
      t.remove :address_1
      t.remove :address_2
      t.remove :city
      t.remove :state
      t.remove :country
      t.remove :post_code
      t.remove :phone
      t.remove :organization
    end
  end
end
