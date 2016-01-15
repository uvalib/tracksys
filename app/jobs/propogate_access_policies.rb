class PropogateAccessPolicies < BaseJob

   def perform( message )
      Job_Log.debug "PropogateAccessPolicies received #{message.to_json}"

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

      # This should never fail becuase availability is checked at an earlier stage, but I will keep it here for sanity checking.
      if @working_unit.availability_policy.nil?
         on_error "Unit #{message[:unit_id]} has no availability value.  Please fill in and restart ingestion."
      else
         availability_policy = @working_unit.availability_policy
      end

      if not @object.availability_policy
         @object.availability_policy = availability_policy
         @object.save!
         on_success "Access policy for object #{@object.class} #{@object.id} is changed to #{availability_policy.name}."
      else
         on_success "Access policy for object #{@object.class} #{@object.id} is already set to #{@object.availability_policy.name} and will not be changed."
      end

      PropogateIndexingScenarios.exec_now({ :unit_id => message[:unit_id], :source => @source, :object_class => @object_class, :object_id => @object_id, :last => @last })
   end
end
