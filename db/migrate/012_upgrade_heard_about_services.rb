class UpgradeHeardAboutServices < ActiveRecord::Migration
  def change
    change_table(:heard_about_services, :bulk => true) do |t|
      t.integer :customers_count, :default => 0
    end
  end
end
