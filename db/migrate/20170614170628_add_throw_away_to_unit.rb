class AddThrowAwayToUnit < ActiveRecord::Migration
  def change
     add_column :units, :throw_away, :boolean, default: false
  end
end
