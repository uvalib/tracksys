class PropogateAccessPolicies < BaseJob

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'source' is required" if message[:source].blank?
      raise "Parameter 'object' is required" if message[:object].blank?
      raise "Parameter 'last' is required" if message[:last].blank?

      source = message[:source]
      object = message[:object]
      last = message[:last]
      unit = message[:unit]

      # This should never fail because availability is checked at an earlier stage, but I will keep it here for sanity checking.
      if unit.availability_policy.nil?
         on_error "Unit #{unit.id} has no availability value.  Please fill in and restart ingestion."
      else
         availability_policy = unit.availability_policy
      end

      if not object.availability_policy
         object.availability_policy = availability_policy
         object.save!
         on_success "Access policy for object #{object.class.name} #{object.id} is changed to #{availability_policy.name}."
      else
         on_success "Access policy for object #{object.class.name} #{object.id} is already set to #{object.availability_policy.name} and will not be changed."
      end

      PropogateIndexingScenarios.exec_now({ :unit => unit, :source => source, :object => object, :last => last }, self)
   end
end
