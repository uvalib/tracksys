class CreateCheckins < ActiveRecord::Migration
  def change
    create_table :checkins do |t|
    	t.integer :unit_id
    	t.integer :admin_user_id
    	t.integer :units_count, :default => 0
      t.timestamps
    end
  end
end
