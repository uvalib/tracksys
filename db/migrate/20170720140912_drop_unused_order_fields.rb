class DropUnusedOrderFields < ActiveRecord::Migration[5.1]
  def change
     remove_column :orders, :date_started, :datetime
     remove_column :orders, :date_permissions_given, :datetime
     remove_column :orders, :entered_by, :string
     add_column :orders, :date_completed, :datetime
  end
end
