class CreateAuditEvents < ActiveRecord::Migration
  def change
    create_table :audit_events do |t|
      t.references :staff_member, index: true
      t.references :auditable, polymorphic: true, index: true
      t.integer :event
      t.string :details
      t.datetime :created_at
    end
  end
end
