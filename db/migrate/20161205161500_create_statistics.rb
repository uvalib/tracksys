class CreateStatistics < ActiveRecord::Migration
  def change
    create_table :statistics do |t|
      t.string :name
      t.string :value
      t.timestamps null: false
    end
  end
end
