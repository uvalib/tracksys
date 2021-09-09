class CreateOrderPDF < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Order", :originator_id=>message[:order].id )
   end

   def do_workflow(message)
      raise "Parameter 'order' is required" if message[:order].blank?

      logger.info("Create order PDF...")
      order = message[:order]
      pdf = BuildOrderPDF.generate_invoice_pdf(order)
      order_dir = File.join("#{DELIVERY_DIR}", "order_#{order.id}")
      Dir.mkdir(order_dir) unless File.exists?(order_dir)
      invoice_file = File.join(order_dir, "#{order.id}.pdf")
      pdf.render_file(invoice_file  )
      logger.info "PDF created for order #{order.id} created at #{invoice_file}"
   end
end
