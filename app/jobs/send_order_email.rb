class SendOrderEmail < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=> "Order", :originator_id=>message[:order_id] )
   end

   def do_workflow(message)
      order = Order.find(message[:order_id])
      email = order.email
      user = message[:user]

      # recreate the email but there is no longer a need to pass correct
      # information because the body will be drawn from order.email
      new_email = OrderMailer.web_delivery(order, ['holding'])
      new_email.body = email.to_s
      new_email.date = Time.now
      new_email.deliver

      order.update(date_customer_notified: Time.now)
      on_success("Email sent to #{order.customer.email} (#{email}) for Order #{order.id}.")

      # If an invoice does not yet exist for this order, create one
      if order.invoices.count == 0

         invoice = Invoice.new
         invoice.order = order
         invoice.date_invoice = Time.now
         invoice.save!
         on_success "A new invoice has been created for order #{order.id}."

         logger.info("Marking order COMPLETE")
         if !order.complete_order(user)
            on_failure("Order is not complete: #{order.errors.full_messages.to_sentence}")
         end
      else
         logger.info "An invoice already exists for order #{order.id}; not creating another."
      end

      # Now clean up any left over files
      # Orders have many units, and each can have a project with a different workflow.
      # Each workflow can have its own base directory. Move each unit individually
      order.units.each do |unit|
         # get the unit assembly dir
         assemble_dir = unit.get_finalization_dir(:assemble_deliverables)
         if Dir.exist? assemble_dir
            # get delete destination; this contains the unit. strip it
            # so we don't end up with nested unit info in the del dir
            del_dest = unit.get_finalization_dir(:delete_from_delivered)
            del_dest = del_dest.split('/')[0...-1].join('/')
            FileUtils.mkdir_p(del_dest) if !Dir.exist? del_dest

            FileUtils.mv assemble_dir, del_dest
         end

         # clean up the ORDER portion of the assembly dir if it is empty
         assemble_order_dir = assemble_dir.split('/')[0...-1].join('/')
         if Dir.exist?(assemble_order_dir) && Dir.empty?(assemble_order_dir)
            FileUtils.rm_rf assemble_order_dir
         end
      end

      on_success "Directory the deliverables for order #{order.id} have been moved from assembly to ready to delete."
   end
end
