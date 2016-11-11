class AddClonedToUnit < ActiveRecord::Migration
  def change
     add_column :units, :cloned, :boolean,  :default => false
  end
end
