# Create a PDF file the contains all order metadata.  Each unit of digitization is enumerate with its metadata records, citation statement,
# Component records, EADRef references and a list of the MasterFile images with their individual metadata.

class CreateOrderPdf < BaseJob

   include BuildOrderPDF

   def do_workflow(message)

      raise "Parameter 'order' is required" if message[:order].blank?
      raise "Parameter 'fee' is required" if message[:fee].blank?

      order = message[:order]
      fee = message[:fee]

      pdf = generate_invoice_pdf(order, fee)

      # Write out the PDF file, ensuring that the order dir exists
      order_dir = File.join("#{DELIVERY_DIR}", "order_#{order.id}")
      Dir.mkdir(order_dir) unless File.exists?(order_dir)
      invoice_file = File.join(order_dir, "#{order.id}.pdf")
      pdf.render_file(invoice_file  )
      logger.info "PDF created for order #{order.id} created at #{invoice_file}"

      CreateOrderEmail.exec_now({:order => order}, self)
   end
end
