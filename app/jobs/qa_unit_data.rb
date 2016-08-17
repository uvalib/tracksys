class QaUnitData < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit' is required" if message[:unit].blank?

      # If this Unit.find fails, a unit with this id does not exist in Tracksys
      unit = message[:unit]
      order = unit.order

      # Create error message holder array
      failure_messages = Array.new

      #-------------------------
      # QA Logic
      #-------------------------

      # Fail if unit.date_patron_deliverables_ready is already filled out
      if unit.date_patron_deliverables_ready
         failure_messages << "Unit #{unit.id} already has a value for date_patron_deliverables_ready."
      end

      # Fail if unit.date_dl_deliverables_ready is already filled out
      if unit.date_dl_deliverables_ready
         failure_messages << "Unit #{unit.id} already has a value for date_dl_deliverables_ready."
      end

      # Must have a unit status
      if not unit.unit_status
         failure_messages << "Unit #{unit.id} must have a valid unit status."
      end

      # Check if unit is assigned to metadata record
      if not unit.metadata
         failure_messages << "Unit #{unit.id} is not assigned to a metadata record."
      end

      # Fail if unit.intended_use is blank
      if not unit.intended_use
         failure_messages << "Unit #{unit.id} has no intended use.  All units that participate in this workflow must have an intended use."
      end

      # In response to DSSR staff's inconsistent use of the date_approved field, this logic will now warn but enforce the inclusion of a date_approved value.
      if not order.date_order_approved?
         # Define and undefine @order_id within this conditional to ensure that only this message is attached to the Order.
         on_failure "Order #{order.id} is not marked as approved.  Since this unit is undergoing finalization, the workflow has automatically updated this value and changed the order_status to approved."
         order.date_order_approved = Time.now
         order.order_status = 'approved'
         if !order.save
            # if status cant be set, fail this  QA
            on_error( order.errors.full_messages.to_sentence )
         end
      end

      #-------------------------
      # Failure Message Handling
      #-------------------------

      if failure_messages.empty?
         on_success "Unit #{unit.id} has passed the QaUnitDataProcessor."
         QaFilesystemAndIviewXml.exec_now( { :unit => unit }, self)
      else
         failure_messages.each do |message|
            on_failure message
            if message == failure_messages.last
               on_error "Unit #{unit.id} has failed the QA Unit Data Processor"
            end
         end
      end
   end
end
