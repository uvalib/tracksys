class AddGroupToStats < ActiveRecord::Migration
  def change
     add_column :statistics, :group, :string
  end
end
