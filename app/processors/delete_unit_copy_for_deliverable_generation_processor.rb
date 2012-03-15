class DeleteUnitCopyForDeliverableGenerationProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :delete_unit_copy_for_deliverable_generation, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :update_unit_date_patron_deliverables_ready
  publishes_to :check_order_ready_for_delivery

  def on_message(message)
    logger.debug "DeleteUnitCopyForDeliverableGenerationProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    @mode = hash[:mode]
    @unit_id = hash[:unit_id]
    @messagable_id = hash[:unit_id]
    @messagable_type = "Unit"   
    @unit_dir = "%09d" % @unit_id
    order_id = Unit.find(@unit_id).order.id

    # Delete logic
    FileUtils.rm_rf(File.join(PROCESS_DELIVERABLES_DIR, @mode, @unit_dir))

    # Send messages
    if @mode == 'patron'
      message = ActiveSupport::JSON.encode({ :order_id => order_id, :unit_id => @unit_id })
      publish :update_unit_date_patron_deliverables_ready, message
      publish :check_order_ready_for_delivery, message
    end
    on_success "Files for unit #{@unit_id} copied for the creation of #{@dl} deliverables have now been deleted."
  end 
end
