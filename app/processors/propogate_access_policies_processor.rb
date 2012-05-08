class PropogateAccessPoliciesProcessor < ApplicationProcessor

  # In order to be ingested into the Fedora repository, all objects must have a 'rightsMetadata' datastream.  That datastream will be populated
  # by the unit.availability value, unless an availability value has already been designated to an object that will be created or updated which is 
  # related to the Unit.  For example, if master_file.availability is designated before ingestion, the value of unit.availability will not be used; if
  # master_file.availability is not designated, the unit.availability value will be used to fill master_file.availability.

  subscribes_to :propogate_access_policies, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :propogate_indexing_scenarios
  
  def on_message(message)  
    logger.debug "PropogateAccessPoliciesProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Validate incoming message
    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    raise "Parameter 'source' is required" if hash[:source].blank?
    raise "Parameter 'object_class' is required" if hash[:object_class].blank?
    raise "Parameter 'object_id' is required" if hash[:object_id].blank?
    raise "Parameter 'last' is required" if hash[:last].blank?

    @source = hash[:source]
    @object_class = hash[:object_class]
    @object_id = hash[:object_id]
    @last = hash[:last]
    @working_unit = Unit.find(hash[:unit_id])
    @object = @object_class.classify.constantize.find(@object_id)
    @messagable_id = hash[:object_id]
    @messagable_type = hash[:object_class]
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)

    @pid = @object.pid
    instance_variable_set("@#{@object.class.to_s.underscore}_id", @object_id)
        
    # This should never fail becuase availability is checked at an earlier stage, but I will keep it here for sanity checking.
    if @working_unit.availability.nil?
      on_error "Unit #{hash[:unit_id]} has no availability value.  Please fill in and restart ingestion."
    else
      availability = @working_unit.availability
    end

    if not @object.availability
      @object.availability = availability
      @object.save!
      on_success "Access policy for object #{@object.class} #{@object.id} is changed to #{availability}."
    else
      on_success "Access policy for object #{@object.class} #{@object.id} is already set to #{@object.availability} and will not be changed."
    end
    
    message = ActiveSupport::JSON.encode({ :unit_id => hash[:unit_id], :source => @source, :object_class => @object_class, :object_id => @object_id, :last => @last })
    publish :propogate_indexing_scenarios, message
  end
end
