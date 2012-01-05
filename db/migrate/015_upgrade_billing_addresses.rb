class UpgradeBillingAddresses < ActiveRecord::Migration
  def change
    add_foreign_key :billing_addresses, :agencies
    add_foreign_key :billing_addresses, :customers
  end
end
