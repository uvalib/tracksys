class UpdateOrderStatusCanceled < BaseJob

  def perform(message)
    Job_Log.debug "UpdateOrderStatusCanceledProcessor received: #{message.to_json}"

    raise "Parameter 'order_id' is required" if message[:order_id].blank?

    set_workflow_type()
    @messagable_id = message[:order_id]
    @messagable_type = "Order"
    @working_order = Order.find(message[:order_id])
    @working_order.order_status = 'canceled'
    @working_order.date_canceled = Time.now
    @working_order.save!

    on_success "The order status has been changed to canceled and the date cancelled has been updated."
  end
end
