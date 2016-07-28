class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :pid
      t.string :external_uri
      t.references :unit, index: true
      t.timestamps null: false
    end
  end
end
