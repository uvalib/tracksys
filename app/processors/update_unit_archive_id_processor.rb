class UpdateUnitArchiveIdProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010
  
  subscribes_to :update_unit_archive_id, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :update_unit_date_archived
  
  def on_message(message)  
    logger.debug "UpdateUnitArchiveIdProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys
    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    raise "Parameter 'source_dir' is required" if hash[:source_dir].blank?
    @messagable_id = hash[:unit_id]
    @messagable_type = "Unit"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)
    
    @unit_id = hash[:unit_id]
    @source_dir = hash[:source_dir]

    # Update archive location.  This presumes that StorNext is the only archive and that its
    # value in the archives table is '2'
    working_unit = Unit.find(@unit_id)

    working_unit.archive_id = 2
    working_unit.save!

    message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :source_dir => @source_dir })
    publish :update_unit_date_archived, message
    on_success "Unit archive id has been updated for unit #{@unit_id}."        
  end
end
