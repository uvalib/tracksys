class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.references :job_status, index: true
      t.integer :level        # enum level: [:info, :warn, :error, :fatal]
      t.text :text
      t.datetime  :created_at
    end
  end
end
