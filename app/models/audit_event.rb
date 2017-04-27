class AuditEvent < ActiveRecord::Base
   enum event: [:status_update]

   belongs_to :auditable, polymorphic: true
   belongs_to :staff_member

   validates :auditable, :presence => true
   validates :event, :presence=>true
   validates :staff_member, :presence=>true

   before_save do
      self.created_at = Time.now
   end

   default_scope { order(created_at: :desc) }
end
