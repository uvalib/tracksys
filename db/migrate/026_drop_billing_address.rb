class DropBillingAddress < ActiveRecord::Base
  def change
    drop_table :billing_addresses
  end
end