class UpdateOrderDateFinalizationBegun < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      @working_unit = Unit.find(message[:unit_id])
      @working_order = @working_unit.order
      @order_id = @working_order.id
      @working_order.date_finalization_begun = Time.now
      @working_order.save!

      on_success "Date Finalization Begun updated for order #{@order_id}"
      CheckUnitDeliveryMode.exec_now({ :unit_id => message[:unit_id] }, self)
   end
end
