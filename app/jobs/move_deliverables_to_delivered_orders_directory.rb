class MoveDeliverablesToDeliveredOrdersDirectory < BaseJob
   require 'fileutils'

   def perform(message)
      Job_Log.debug "MoveDeliverablesToDeliveredOrdersDirectoryProcessor received: #{message.to_json}"

      @order_id = message[:order_id]
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()

      FileUtils.mv File.join(ASSEMBLE_DELIVERY_DIR, "order_#{@order_id}"), File.join(DELETE_DIR_DELIVERED_ORDERS, "order_#{@order_id}")
      on_success "Directory the deliverables for order #{@order_id} have been moved from #{ASSEMBLE_DELIVERY_DIR} to #{DELETE_DIR_DELIVERED_ORDERS}."
   end
end
