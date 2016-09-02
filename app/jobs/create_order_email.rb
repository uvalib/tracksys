class CreateOrderEmail < BaseJob

   def do_workflow(message)
      raise "Parameter 'order' is required" if message[:order].blank?

      order = message[:order]
      delivery_dir = File.join("#{DELIVERY_DIR}", "order_#{order.id}")
      delivery_files = [ File.join("order_#{order.id}", "#{order.id}.pdf") ]
      Dir.glob("#{delivery_dir}/*.zip") do |zf|
         # strip off the full path; only add: order_dir/file.zip
         delivery_files << zf.split("/patron/")[1]
      end

      email = OrderMailer.web_delivery(order, delivery_files)
      order.update_attribute(:email, email.body)
      on_success "An email for web delivery method created for order #{order.id}"
   end
end
