class PropogateIndexingScenarios < BaseJob

   # In order to be ingested into the Fedora repository, all objects must have a 'rightsMetadata' datastream.  That datastream will be populated
   # by the unit.availability value, unless an availability value has already been designated to an object that will be created or updated which is
   # related to the Unit.  For example, if master_file.availability is designated before ingestion, the value of unit.availability will not be used; if
   # master_file.availability is not designated, the unit.availability value will be used to fill master_file.availability.

   def perform(message)
      Job_Log.debug "PropogateIndexingScenariosProcessor received: #{message.to_json}"

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'source' is required" if message[:source].blank?
      raise "Parameter 'object_class' is required" if message[:object_class].blank?
      raise "Parameter 'object_id' is required" if message[:object_id].blank?
      raise "Parameter 'last' is required" if message[:last].blank?

      @source = message[:source]
      @object_class = message[:object_class]
      @object_id = message[:object_id]
      @last = message[:last]
      @working_unit = Unit.find(message[:unit_id])
      @object = @object_class.classify.constantize.find(@object_id)
      @messagable_id = message[:object_id]
      @messagable_type = message[:object_class]
      set_workflow_type()
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

      PropogateDiscoverability.exec_now({ :unit_id => message[:unit_id], :source => @source, :object_class => @object_class, :object_id => @object_id, :last => @last })
   end
end
