class UpgradeBillingAddresses < ActiveRecord::Migration
  def change
    change_table(:billing_addresses, :bulk => true) do |t|
      t.foreign_key :agencies
      t.foreign_key :customers
    end
  end
end
