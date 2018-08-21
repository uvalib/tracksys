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

      # Now clean up any left over files
      # Orders have many units, and each can have a project with a different workflow.
      # Each workflow can have its own base directory. Move each unit individually
      order.units.each do |unit|
         # get the unit assembly dir
         assemble_dir = Finder.finalization_dir(unit, :assemble_deliverables)
         if Dir.exist? assemble_dir
            # get delete destination; this contains the unit. Example:
            #     /digiserv-production/ready_to_delete/delivered_orders/order_10059/49590
            del_dest = Finder.finalization_dir(unit, :delete_from_delivered)
            if Dir.exist?(del_dest)
               # if a unit dir exists in the ready to delete directory, remove it
               # as it will be replaced by the current files below
               FileUtils.rm_rf del_dest
            end

            # strip unit ID so we don't end up with nested unit info in the del dir
            del_dest = del_dest.split('/')[0...-1].join('/')
            FileUtils.mkdir_p(del_dest) if !Dir.exist? del_dest

            FileUtils.mv assemble_dir, del_dest
         end
      end

      # all of the assembled files have been moved. REmove the order dir
      assemble_order_dir = assemble_dir.split('/')[0...-1].join('/')
      if Dir.exist?(assemble_order_dir)
         FileUtils.rm_rf assemble_order_dir
      end
      logger.info "Directory the deliverables for order #{order.id} have been moved from assembly to ready to delete."

      # Now that all of the above is done, the order is considered complete. Mark
      # it as such if it is not already done
      if order.order_status != "completed"
         if !order.complete_order(user)
            logger.info("Marking order COMPLETE")
            on_failure("Order is not complete: #{order.errors.full_messages.to_sentence}")
         else
            logger.info "Order is now complete"
         end
      end
   end
end
