class PropogateDiscoverabilityProcessor < ApplicationProcessor

  # In order to be ingested into the Fedora repository, all objects must have a 'rightsMetadata' datastream.  That datastream will be populated
  # by the unit.discoverability value, unless an discoverability value has already been designated to an object that will be created or updated which is 
  # related to the Unit.  For example, if master_file.discoverability is designated before ingestion, the value of unit.discoverability will not be used; if
  # master_file.discoverability is not designated, the unit.discoverability value will be used to fill master_file.discoverability.

  subscribes_to :propogate_discoverability, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :create_new_fedora_objects
  
  def on_message(message)  
    logger.debug "PropogateDiscoverabilityProcessor received: " + message
    
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
        
    # This should never fail becuase discoverability is checked at an earlier stage, but I will keep it here for sanity checking.
    if @working_unit.master_file_discoverability.nil?
      on_error "Unit #{hash[:unit_id]} has no discoverability value.  Please fill in and restart ingestion."
    else
      discoverability = @working_unit.master_file_discoverability
    end

    if not @object.discoverability
      @object.discoverability = discoverability
      @object.save!
      on_success "Discoverability for object #{@object.class} #{@object.id} is changed to #{discoverability}."
    else
      on_success "Discoverability for object #{@object.class} #{@object.id} is already set to #{@object.discoverability} and will not be changed."
    end
    
    message = ActiveSupport::JSON.encode({ :source => @source, :object_class => @object_class, :object_id => @object_id, :last => @last })
    publish :create_new_fedora_objects, message
  end
end
