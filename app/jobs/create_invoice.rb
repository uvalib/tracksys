class CreateInvoice < BaseJob

   def perform(message)
      Job_Log.debug "CreateInvoiceProcessor received: #{message.to_json}"

      raise "Parameter 'order_id' is required" if message[:order_id].blank?

      @order_id = message[:order_id]
      order = Order.find(message[:order_id])
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()

      # Create invoice
      invoice = Invoice.new
      invoice.order=order
      invoice.date_invoice=Time.now
      invoice.invoice_copy=File.read("#{ASSEMBLE_DELIVERY_DIR}/order_#{@order_id}/#{@order_id}.pdf")
      invoice.save!

      MoveDeliverablesToDeliveredOrdersDirectory.exec_now({:order_id => @order_id})

      on_success "A new invoice has been created for order #{@order_id}."
   end
end
