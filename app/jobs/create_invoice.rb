class CreateInvoice < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Order", :originator_id=>message[:order_id])
   end

   def do_workflow(message)

      raise "Parameter 'order_id' is required" if message[:order_id].blank?

      order_id = message[:order_id]
      order = Order.find(message[:order_id])

      # Create invoice
      invoice = Invoice.new
      invoice.order=order
      invoice.date_invoice=Time.now
      invoice.invoice_copy=File.read("#{ASSEMBLE_DELIVERY_DIR}/order_#{order_id}/#{order_id}.pdf")
      invoice.save!

      MoveDeliverablesToDeliveredOrdersDirectory.exec_now({:order_id => order_id}, self)

      on_success "A new invoice has been created for order #{order_id}."
   end
end
