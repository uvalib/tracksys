class UpdateOrderStatusApproved < BaseJob

  def perform(message)
    Job_Log.debug "UpdateOrderStatusApprovedProcessor received: #{message.to_json}"

    raise "Parameter 'order_id' is required" if message[:order_id].blank?
    @workflow_type = 'patron'
    @messagable_id = message[:order_id]
    @messagable_type = "Order"
    set_workflow_type()
    @working_order = Order.find(message[:order_id])
    @working_order.order_status = 'approved'
    @working_order.date_order_approved = Time.now
    @working_order.save!

    on_success "The order status has been changed to approved and the date approved has been updated."
  end
end
