class PropogateDiscoverability < BaseJob
   # In order to be ingested into the Fedora repository, all objects must have a 'rightsMetadata' datastream.  That datastream will be populated
   # by the unit.discoverability value, unless an discoverability value has already been designated to an object that will be created or updated which is
   # related to the Unit.  For example, if master_file.discoverability is designated before ingestion, the value of unit.discoverability will not be used; if
   # master_file.discoverability is not designated, the unit.discoverability value will be used to fill master_file.discoverability.

   def perform(message)
      Job_Log.debug "PropogateDiscoverabilityProcessor received: #{message}"

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

      # This should never fail becuase discoverability is checked at an earlier stage, but I will keep it here for sanity checking.
      if @working_unit.master_file_discoverability.nil?
         on_error "Unit #{message[:unit_id]} has no discoverability value.  Please fill in and restart ingestion."
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

      CreateNewFedoraObjects.exec_now({ :source => @source, :object_class => @object_class, :object_id => @object_id, :last => @last })
   end
end
