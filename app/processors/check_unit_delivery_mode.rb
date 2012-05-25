class CheckUnitDeliveryModeProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :check_unit_delivery_mode, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :copy_unit_for_deliverable_generation
  publishes_to :send_unit_to_archive
  
  def on_message(message)
    logger.debug "CheckUnitDeliveryModeProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Validate incoming messages
    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank? 

    @unit_id = hash[:unit_id]
    @working_unit = Unit.find(@unit_id)
    @messagable_id = hash[:unit_id]
    @messagable_type = "Unit"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)
    @unit_dir = "%09d" % @unit_id

    @source_dir = File.join(IN_PROCESS_DIR, @unit_dir)

    # The filter to determine which units get sent to repo must be worked on later at an appropriate time.    
    if @working_unit.include_in_dl and @working_unit.availability and @working_unit.intended_use.description == "Digital Collection Building"
      @mode = "dl"
      message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :mode => @mode, :source_dir => @source_dir })
      publish :copy_unit_for_deliverable_generation, message
      on_success "Unit #{@unit_id} requires the creation of repository deliverables."
    end

    if not @working_unit.intended_use.description == "Digital Collection Building" and not @working_unit.include_in_dl
      @mode = "patron"
      on_success = "Unit #{@unit_id} requires the creation of patron deliverables."
      message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :mode => @mode, :source_dir => @source_dir })
      publish :copy_unit_for_deliverable_generation, message
    end

    if @working_unit.include_in_dl and @working_unit.availability and not @working_unit.intended_use.description == "Digital Collection Building"
      @mode = "both"
      on_success = "Unit #{@unit_id} requires the creation of patron deliverables."
      message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :mode => @mode, :source_dir => @source_dir })
      publish :copy_unit_for_deliverable_generation, message
    end

    # All units with no deliverables (either patron or DL) get sent to the archive at this step.
    if not @working_unit.intended_use_deliverable_resolution and not @working_unit.intended_use_deliverable_format and not @working_unit.transcription_format and not @working_unit.include_in_dl
      on_success "Unit #{@unit_id} has no deliverables so is being sent directly to the archive."
      message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :internal_dir => 'yes', :source_dir => IN_PROCESS_DIR })
      publish :send_unit_to_archive, message
    end

    # if @working_unit.order.date_customer_notified or @working_unit.order.date_patron_deliverables_complete or @working_unit.order.date_archiving_complete
    # If the above is true, this unit has already been delivered and/or archived.  So if it is being re-run through the system, it probably just needs to be archived again.

    # on_failure "Unit #{@unit_id} has it's order date_customer_notified filled so it is only going to be archived."
    # message = ActiveSupport::JSON.encode({:unit_id => @unit_id, :internal_dir => 'yes', :source_dir => IN_PROCESS_DIR})
    # publish :send_unit_to_archive, message

    #else
      # Every intended_use with the exception of 'Digital Collection Building' indicates a patron request.  Not all units with
      # the intended use of 'Digital Collection Building' are slated for the DL at this time, however.  Therefore we must 
      # rely on the built-in DL switches.


    #end
  end
end
