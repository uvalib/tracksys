class UpdateOrderDatePatronDeliverablesComplete < BaseJob

   def perform(message)
      Job_Log.debug "UpdateOrderDatePatronDeliverablesCompleteProcessor received: #{message.to_json}"

      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)

      @working_order.date_patron_deliverables_complete = Time.now
      @working_order.save!

      QaOrderData.exec_now({ :order_id => @order_id })
      on_success "All patron deliverables of order #{@order_id} have been created."
   end
end
