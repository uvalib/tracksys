class UpdateUnitDateDlDeliverablesReadyProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010
  
  subscribes_to :update_unit_date_dl_deliverables_ready, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :send_commit_to_solr
    
  def on_message(message)  
    logger.debug "UpdateUnitDateDlDeliverablesProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    @messagable_id = hash[:unit_id]
    @messagable_type = "Unit"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)
    
    @unit_id = hash[:unit_id]

    @working_unit = Unit.find(@unit_id)
    @messagable = @working_unit
    @working_unit.update_attribute(:date_dl_deliverables_ready, Time.now)

    message = ActiveSupport::JSON.encode({ :unit_id => @unit_id })
    publish :send_commit_to_solr,  message   

    on_success "Unit #{@unit_id} has completed ingestion to #{FEDORA_REST_URL}."
  end
end
