class CheckOrderFee < BaseJob

   def perform(message)
      Job_Log.debug "CheckOrderFeeProcessor received: #{message.to_json}"

      # Set unit variables
      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()

      # If there is a value for 'fee_estimated' then there must be a value in 'fee_actual'.
      # If there is no value for 'fee_estimated', the workfow sould proceed.

      if @working_order.fee_estimated and not @working_order.fee_actual
         on_error "Error with order fee: Order #{@order_id} has an estimated fee but no actual fee."
      elsif @working_order.fee_actual and not @working_order.fee_estimated
         on_error "Error with order fee: Check if customer approved fees because the estimated fee is blank while the actual fee is not."
      elsif @working_order.fee_estimated and @working_order.fee_actual
         if @working_order.fee_estimated.to_i.eql?(0) and not @working_order.fee_actual.to_i.eql?(0)
            on_error "Error with order fee: Fee estimated is equal to 0.00 but the fee actual is greater than that.  Check customer correspondence and update information."
         elsif @working_order.fee_estimated.to_i.eql?(0) and @working_order.fee_actual.to_i.eql?(0)
            CreateOrderPdf.exec_now({ :order_id => @order_id, :fee => "none" })
            on_success "Order fee checked.  #{@order_id} has no fees associated with it."
         else
            fee = @working_order.fee_actual
            CreateOrderPdf.exec_now({ :order_id => @order_id, :fee => fee })
            on_success "Order fee checked. #{@order_id} has a fee of #{fee.to_i} and both the estimated and actual fee values are greater than 0.00"
         end
      else
         CreateOrderPdf.exec_now({ :order_id => @order_id, :fee => "none" })
         on_success "Order fee checked. #{@order_id} has no fees associated with it."
      end
   end
end
