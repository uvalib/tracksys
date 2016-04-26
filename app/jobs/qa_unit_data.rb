class QaUnitData < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      @unit_id = message[:unit_id]

      # If this Unit.find fails, a unit with this id does not exist in Tracksys
      @working_unit = Unit.find(@unit_id)
      @working_order = @working_unit.order

      # Create error message holder array
      failure_messages = Array.new

      #-------------------------
      # QA Logic
      #-------------------------

      # Fail if @working_unit.date_patron_deliverables_ready is already filled out
      if @working_unit.date_patron_deliverables_ready
         failure_messages << "Unit #{@unit_id} already has a value for date_patron_deliverables_ready."
      end

      # Fail if @working_unit.date_dl_deliverables_ready is already filled out
      if @working_unit.date_dl_deliverables_ready
         failure_messages << "Unit #{@unit_id} already has a value for date_dl_deliverables_ready."
      end

      # Must have a unit status
      if not @working_unit.unit_status
         failure_messages << "Unit #{@unit_id} must have a valid unit status."
      end

      # Check if unit is assigned to bibl record
      if not @working_unit.bibl
         failure_messages << "Unit #{@unit_id} is not assigned to a bibl record."
      end

      # Fail if @working_unit.intended_use is blank
      if not @working_unit.intended_use
         failure_messages << "Unit #{@unit_id} has no intended use.  All units that participate in this workflow must have an intended use."
      end

      # In response to DSSR staff's inconsistent use of the date_approved field, this logic will now warn but enforce the inclusion of a date_approved value.
      if not @working_order.date_order_approved?
         # Define and undefine @order_id within this conditional to ensure that only this message is attached to the Order.
         @order_id = @working_order.id
         on_failure "Order #{@order_id} is not marked as approved.  Since this unit is undergoing finalization, the workflow has automatically updated this value and changed the order_status to approved."
         @working_order.date_order_approved = Time.now
         @working_order.order_status = 'approved'
         if !@working_order.save
            # if status cant be set, fail this  QA
            on_error( @working_order.errors.full_messages.to_sentence )
         end
         @order_id = nil
      end

      #-------------------------
      # Failure Message Handling
      #-------------------------

      if failure_messages.empty?
         on_success "Unit #{@unit_id} has passed the QaUnitDataProcessor."
         QaFilesystemAndIviewXml.exec_now( { :unit_id => @unit_id }, self)
      else
         failure_messages.each do |message|
            on_failure message
            if message == failure_messages.last
               on_error "Unit #{@unit_id} has failed the QA Unit Data Processor"
            end
         end
      end
   end
end
