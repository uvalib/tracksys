class LinkToAs < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"StaffMember", :originator_id=>message[:staff_member].id )
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'as_url' is required" if message[:as_url].blank?
      raise "Parameter 'staff_member' is required" if message[:staff_member].blank?
      ArchivesSpace.link(message[:unit_id], message[:as_url], logger)
   end
end
