class MoveDeliverablesToDeliveredOrdersDirectory < BaseJob
   require 'fileutils'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Order", :originator_id=>message[:order_id])
   end

   def do_workflow(message)
      order_id = message[:order_id]
      FileUtils.mv File.join(ASSEMBLE_DELIVERY_DIR, "order_#{order_id}"), File.join(DELETE_DIR_DELIVERED_ORDERS, "order_#{order_id}")
      on_success "Directory the deliverables for order #{order_id} have been moved from #{ASSEMBLE_DELIVERY_DIR} to #{DELETE_DIR_DELIVERED_ORDERS}."
   end
end
