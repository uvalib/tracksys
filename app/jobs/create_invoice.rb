class CreateInvoice < BaseJob
   require 'fileutils'

   def do_workflow(message)
      raise "Parameter 'order' is required" if message[:order].blank?

      order = message[:order]

      # Create invoice
      invoice = Invoice.new
      invoice.order = order
      invoice.date_invoice = Time.now
      invoice.invoice_copy = File.read("#{ASSEMBLE_DELIVERY_DIR}/order_#{order.id}/#{order.id}.pdf")
      invoice.save!
      on_success "A new invoice has been created for order #{order.id}."

      FileUtils.mv File.join(ASSEMBLE_DELIVERY_DIR, "order_#{order.id}"), File.join(DELETE_DIR_DELIVERED_ORDERS, "order_#{order.id}")
      on_success "Directory the deliverables for order #{order.id} have been moved from #{ASSEMBLE_DELIVERY_DIR} to #{DELETE_DIR_DELIVERED_ORDERS}."
   end
end
