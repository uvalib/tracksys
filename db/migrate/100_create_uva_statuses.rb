class CreateUvaStatuses < ActiveRecord::Migration
  def change
    create_table :uva_statuses do |t|
      t.string :name
      t.timestamps
    end
  end
end
