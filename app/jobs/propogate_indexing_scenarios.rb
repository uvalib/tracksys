class PropogateIndexingScenarios < BaseJob

   # In order to be ingested into the Fedora repository, all objects must have a 'rightsMetadata' datastream.  That datastream will be populated
   # by the unit.availability value, unless an availability value has already been designated to an object that will be created or updated which is
   # related to the Unit.  For example, if master_file.availability is designated before ingestion, the value of unit.availability will not be used; if
   # master_file.availability is not designated, the unit.availability value will be used to fill master_file.availability.

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

      if not unit.indexing_scenario
         # The first indexing scenario should be default
         indexing_scenario = IndexingScenario.find(1)
         unit.indexing_scenario = indexing_scenario
         unit.save!
         on_failure "Unit #{unit.id} has no indexing scenario selected so it is assumed to use the default scenario."
      else
         indexing_scenario = unit.indexing_scenario
      end

      if not object.indexing_scenario
         object.indexing_scenario = indexing_scenario
         object.save!
         on_success "Indexing scenario for object #{object.class.name} #{object.id} is changed to #{indexing_scenario.name}."
      else
         on_success "Indexing scenario for object #{object.class.name} #{object.id} is already set to #{object.indexing_scenario.name} and will not be changed."
      end

      PropogateDiscoverability.exec_now({ :unit => unit, :source => source, :object => object, :last => last }, self)
   end
end
