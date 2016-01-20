class UpdateOrderDatePatronDeliverablesComplete < BaseJob

   def perform(message)
      Job_Log.debug "UpdateOrderDatePatronDeliverablesCompleteProcessor received: #{message.to_json}"

      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()

      @working_order.date_patron_deliverables_complete = Time.now
      @working_order.save!

      on_success "All patron deliverables of order #{@order_id} have been created."
      QaOrderData.exec_now({ :order_id => @order_id })
   end
end
