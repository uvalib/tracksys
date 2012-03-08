class UpgradeAgencies < ActiveRecord::Migration
  def change

    # Build Primary Address
    Agency.all.each {|a|
      a.build_primary_address(:address_1 => a.address_1.to_s, :address_2 => a.address_2.to_s, :city => a.city.to_s, :state => a.state.to_s, :country => a.country, :post_code => a.post_code.to_s, :phone => a.phone.to_s)
      a.save
    }

    # Build Billing Address
    class BillingAddress < ActiveRecord::Base
    end
    BillingAddress.all.each {|ba|
      a = Agency.find(ba.agency_id)
      a.build_billable_address(:address_1 => ba.address_1.to_s, :address_2 => ba.address_2.to_s, :city => ba.city.to_s, :state => ba.state.to_s, :country => ba.country, :post_code => ba.post_code.to_s, :phone => ba.phone.to_s, :organization => ba.organization.to_s)
      a.save
    }

    change_table(:agencies, :bulk => true) do |t|
      t.remove :address_1
      t.remove :address_2
      t.remove :city
      t.remove :state
      t.remove :country
      t.remove :post_code
      t.remove :phone
      t.integer :orders_count, :default => 0
    end
  end
end
