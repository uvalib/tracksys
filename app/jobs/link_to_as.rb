class LinkToAs < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"StaffMember", :originator_id=>message[:staff_member].id )
   end

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'as_url' is required" if message[:as_url].blank?
      raise "Parameter 'staff_member' is required" if message[:staff_member].blank?

      unit = message[:unit]
      ArchivesSpace.link(unit.id, message[:as_url], message[:publish], logger)
   end
end
