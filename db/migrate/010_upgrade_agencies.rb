class UpgradeAgencies < ActiveRecord::Migration
  def change

    Agency.all.each {|a|
      a.build_primary_address(:address_1 => a.address_1.to_s, :address_2 => a.address_2.to_s, :city => a.city.to_s, :state => a.state.to_s, :country => a.country, :post_code => a.post_code.to_s, :phone => a.phone.to_s, :organization => a.organization.to_s)
    
      if a.billing_address
        a.build_billing_address(:address_1 => a.billing_address.address_1.to_s, :address_2 => a.billing_address.address_2.to_s, :city => a.billing_address.city.to_s, :state => a.billing_address.state.to_s, :country => a.billing_address.country, :post_code => a.billing_address.post_code.to_s, :phone => a.billing_address.phone.to_s, :organization => a.billing_address.organization.to_s)
      end
      a.save!
    }

    change_table(:agencies, :bulk => true) do |t|
      t.remove :address_1
      t.remove :address_2
      t.remove :city
      t.remove :state
      t.remove :country
      t.remove :post_code
      t.remove :phone
      t.remove :organization
      t.integer :orders_count, :default => 0
    end
  end
end
