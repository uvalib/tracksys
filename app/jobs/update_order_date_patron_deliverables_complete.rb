class UpdateOrderDatePatronDeliverablesComplete < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Order", :originator_id=>message[:order_id])
   end

   def do_workflow(message)
      order = Order.find(message[:order_id])
      order.date_patron_deliverables_complete = Time.now
      order.save!

      on_success "All patron deliverables of order #{message[:order_id]} have been created."
      QaOrderData.exec_now({ :order_id => @order_id }, self)
   end
end
