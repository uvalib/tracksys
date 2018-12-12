class CreateApTrustStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :ap_trust_statuses do |t|
      t.references :metadata, index: true
      t.string :etag 
      t.string :status 
      t.string :note
      t.string :object_id 
      t.datetime :submitted_at, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :finished_at
    end
  end
end
