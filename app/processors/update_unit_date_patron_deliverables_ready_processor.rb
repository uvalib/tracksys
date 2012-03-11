class UpdateUnitDatePatronDeliverablesReadyProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010
  
  subscribes_to :update_unit_date_patron_deliverables_ready, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)  
    logger.debug "UpdateUnitDatePatronDeliverablesProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?

    @unit_id = hash[:unit_id]

    @working_unit = Unit.find(@unit_id)
    @messagable = @working_unit
    @working_unit.date_patron_deliverables_ready = Time.now
    @working_unit.save!
    on_success "Date patron deliverables ready for unit #{@unit_id} has been updated."

  end
end
