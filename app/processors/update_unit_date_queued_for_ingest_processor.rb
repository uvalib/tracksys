class UpdateUnitDateQueuedForIngestProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010
  
  subscribes_to :update_unit_date_queued_for_ingest, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :queue_objects_for_fedora
  
  def on_message(message)  
    logger.debug "UpdateUnitDateQueuedForIngestProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Validate incoming message
    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    raise "Parameter 'source' is required" if hash[:source].blank?
    
    @unit_id = hash[:unit_id]
    @source = hash[:source]
    @working_unit = Unit.find(@unit_id)
    @messagable = @working_unit

    # Update date_unit_queued_for_ingest value
    @working_unit.date_queued_for_ingest = Time.now
    @working_unit.save!

    message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :source => @source })
    publish :queue_objects_for_fedora, message
    on_success "Date queued for ingest for Unit #{@unit_id} has been updated."
  end
end
