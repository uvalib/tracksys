class RemoveOrdersCountFromBibls < ActiveRecord::Migration
  def up
    remove_column :bibls, :orders_count
  end

  def down
    add_column :bibls, :orders_count, :integer
  end
end
