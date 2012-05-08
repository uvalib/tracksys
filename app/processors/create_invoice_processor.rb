class CreateInvoiceProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010
  
  subscribes_to :create_invoice, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :move_deliverables_to_delivered_orders_directory
  
  def on_message(message)  
    logger.debug "CreateInvoiceProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys
    raise "Parameter 'order_id' is required" if hash[:order_id].blank?

    @order_id = hash[:order_id]
    order = Order.find(hash[:order_id])
    @messagable_id = hash[:order_id]
    @messagable_type = "Order"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)

    # Create invoice
    invoice = Invoice.new
    invoice.order=order
    invoice.date_invoice=Time.now
    invoice.invoice_copy=File.read("#{ASSEMBLE_DELIVERY_DIR}/order_#{@order_id}/#{@order_id}.pdf")
    invoice.save!

    message = ActiveSupport::JSON.encode({:order_id => @order_id})
    publish :move_deliverables_to_delivered_orders_directory, message

    on_success "A new invoice has been created for order #{@order_id}."        
  end
end
