class UpdateUnitDateArchivedProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010
  
  subscribes_to :update_unit_date_archived, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :check_order_date_archiving_complete
  publishes_to :move_completed_directory_to_delete_directory
  
  def on_message(message)  
    logger.debug "UpdateUnitDateArchivedProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    raise "Parameter 'source_dir' is required" if hash[:source_dir].blank?

    @messagable_id = hash[:unit_id]
    @messagable_type = "Unit"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)
    
    @unit_id = hash[:unit_id]
    @source_dir = hash[:source_dir]

    @working_unit = Unit.find(@unit_id)
    @working_unit.update_attribute(:date_archived, Time.now)
    @working_unit.master_files.each {|mf|
      mf.update_attributes(:date_archived => Time.now)
    }

    message = ActiveSupport::JSON.encode({ :unit_id => @unit_id })
    publish :check_order_date_archiving_complete, message

    # Now that all archiving work for the unit is done, it (and any subsidary files) must be moved to the ready_to_delete directory 
    message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :source_dir => @source_dir})
    publish :move_completed_directory_to_delete_directory, message

    on_success "Date Archived updated for for unit #{@unit_id}"
  end
end
