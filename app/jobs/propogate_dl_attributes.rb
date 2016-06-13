class PropogateDlAttributes < BaseJob

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'source' is required" if message[:source].blank?
      raise "Parameter 'object' is required" if message[:object].blank?

      source = message[:source]
      object = message[:object]
      unit = message[:unit]
      bibl = unit.bibl

      # sanity check all attributes are in place
      if bibl.availability_policy.nil?
         on_error "Bibl #{unit.bibl.id} for Unit #{unit.id} has no availability value.  Please fill in and restart ingestion."
      end
      if unit.master_file_discoverability.nil?
         on_error "Unit #{unit.id} has no discoverability value.  Please fill in and restart ingestion."
      end
      if unit.indexing_scenario.nil?
         unit.indexing_scenario = IndexingScenario.find(1)
         unit.save!
         on_failure "Unit #{unit.id} has no indexing scenario selected so it is assumed to use the default scenario."
      end

      if object.indexing_scenario.nil?
         object.indexing_scenario = unit.indexing_scenario
         object.save!
         on_success "Indexing scenario for object #{object.class.name} #{object.id} is changed to #{unit.indexing_scenario.name}."
      else
         on_success "Indexing scenario for object #{object.class.name} #{object.id} is already set to #{object.indexing_scenario.name} and will not be changed."
      end

      if object.discoverability.nil?
         object.discoverability = unit.master_file_discoverability
         object.save!
         on_success "Discoverability for object #{object.class.name} #{object.id} is changed to #{unit.master_file_discoverability}."
      else
         on_success "Discoverability for object #{object.class.name} #{object.id} is already set to #{object.discoverability} and will not be changed."
      end

      # All ingestable objects have a date_dl_ingest attribute which can be updated at this time.
      object.update_attribute(:date_dl_ingest, Time.now)

      # Create deliverables
      if object.is_a? MasterFile
         file_path = File.join(source, object.filename)
         CreateDlDeliverables.exec_now({ :source => file_path, :master_file=> object }, self)
      end
   end
end
