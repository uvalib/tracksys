class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.references :unit, index: true, foreign_key: true
      t.string :filename
      t.string :md5
      t.text :description

      t.timestamps null: false
    end
  end
end
