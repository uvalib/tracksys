class CheckOrderFee < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Order", :originator_id=>message[:order].id )
   end

   def do_workflow(message)
      @order = message[:order]

      # If there is a value for 'fee_estimated' then there must be a value in 'fee_actual'.
      # If there is no value for 'fee_estimated', the workfow sould proceed.

      if @order.fee_estimated and not @order.fee_actual
         on_error "Error with order fee: Order #{@order.id} has an estimated fee but no actual fee."
      elsif @order.fee_actual and not @order.fee_estimated
         on_error "Error with order fee: Check if customer approved fees because the estimated fee is blank while the actual fee is not."
      elsif @order.fee_estimated and @order.fee_actual
         if @order.fee_estimated.to_i.eql?(0) and not @order.fee_actual.to_i.eql?(0)
            on_error "Error with order fee: Fee estimated is equal to 0.00 but the fee actual is greater than that.  Check customer correspondence and update information."
         elsif @order.fee_estimated.to_i.eql?(0) and @order.fee_actual.to_i.eql?(0)
            on_success "Order fee checked.  #{@order.id} has no fees associated with it."
            CreateOrderPdf.exec_now({ :order => @order, :fee => "none" }, self)
         else
            fee = @order.fee_actual
            on_success "Order fee checked. #{@order.id} has a fee of #{fee.to_i} and both the estimated and actual fee values are greater than 0.00"
            CreateOrderPdf.exec_now({ :order => @order, :fee => fee }, self)
         end
      else
         on_success "Order fee checked. #{@order.id} has no fees associated with it."
         CreateOrderPdf.exec_now({ :order => @order, :fee => "none" }, self)
      end
   end
end
