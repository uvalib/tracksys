class CreateJobStatuses < ActiveRecord::Migration
   def change
     create_table :job_statuses do |t|
       t.string :status, :null => false, :default => "pending"
       t.datetime :started_at
       t.datetime :ended_at
       t.integer :failures, :null => false, :default => 0
       t.string :error
       t.text :backtrace
       t.references :originator, polymorphic: true, index: true
       t.timestamps
     end
   end
end
