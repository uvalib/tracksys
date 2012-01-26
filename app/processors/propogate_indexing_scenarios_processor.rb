class PropogateIndexingScenariosProcessor < ApplicationProcessor

  # In order to be ingested into the Fedora repository, all objects must have a 'rightsMetadata' datastream.  That datastream will be populated
  # by the unit.availability value, unless an availability value has already been designated to an object that will be created or updated which is 
  # related to the Unit.  For example, if master_file.availability is designated before ingestion, the value of unit.availability will not be used; if
  # master_file.availability is not designated, the unit.availability value will be used to fill master_file.availability.

  subscribes_to :propogate_indexing_scenarios, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :propogate_discoverability
  
  def on_message(message)  
    logger.debug "PropogateIndexingScenariosProcessor received: " + message
    
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

    @pid = @object.pid
    instance_variable_set("@#{@object.class.to_s.underscore}_id", @object_id)
        
    if not @working_unit.indexing_scenario
      # The first indexing scenario should be default
      indexing_scenario = IndexingScenario.find(1)
      @working_unit.indexing_scenario = indexing_scenario
      @working_unit.save!
      on_failure "Unit #{@object_id} has no indexing scenario selected so it is assumed to use the default scenario."
    else
      indexing_scenario = @working_unit.indexing_scenario
    end

    if not @object.indexing_scenario
      @object.indexing_scenario = indexing_scenario
      @object.save!
      on_success "Indexing scenario for object #{@object.class} #{@object.id} is changed to #{indexing_scenario.name}."
    else
      on_success "Indexing scenario for object #{@object.class} #{@object.id} is already set to #{@object.indexing_scenario.name} and will not be changed."
    end
    
    message = ActiveSupport::JSON.encode({ :unit_id => hash[:unit_id], :source => @source, :object_class => @object_class, :object_id => @object_id, :last => @last })
    publish :propogate_discoverability, message
  end
end
