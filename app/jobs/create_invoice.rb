class CreateInvoice < BaseJob
   require 'fileutils'

   def do_workflow(message)
      raise "Parameter 'order' is required" if message[:order].blank?

      order = message[:order]

      # Create invoice
      invoice = Invoice.new
      invoice.order = order
      invoice.date_invoice = Time.now
      invoice.save!
      on_success "A new invoice has been created for order #{order.id}."

      del_dest = File.join(DELETE_DIR_DELIVERED_ORDERS, "order_#{order.id}")
      if Dir.exist? del_dest
         del_dest = "#{del_dest}_v#{Time.now.to_i}"
      end
      FileUtils.mv File.join(ASSEMBLE_DELIVERY_DIR, "order_#{order.id}"), del_dest
      on_success "Directory the deliverables for order #{order.id} have been moved from #{ASSEMBLE_DELIVERY_DIR} to #{del_dest}."
   end
end
