class MoveDeliverablesToDeliveredOrdersDirectoryProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010
  require 'fileutils'

  subscribes_to :move_deliverables_to_delivered_orders_directory, {:ack=>'client', 'activemq.prefetchSize' => 1}
   
  def on_message(message)

    logger.debug "MoveDeliverablesToDeliveredOrdersDirectoryProcessor received: " + message

    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys
    @order_id = hash[:order_id]
    @messagable_id = hash[:order_id]
    @messagable_type = "Order"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)

    FileUtils.mv File.join(ASSEMBLE_DELIVERY_DIR, "order_#{@order_id}"), File.join(DELETE_DIR_DELIVERED_ORDERS, "order_#{@order_id}")
    on_success "Directory the deliverables for order #{@order_id} have been moved from #{ASSEMBLE_DELIVERY_DIR} to #{DELETE_DIR_DELIVERED_ORDERS}."
  end
end
