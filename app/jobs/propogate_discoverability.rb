class PropogateDiscoverability < BaseJob
   # In order to be ingested into the Fedora repository, all objects must have a 'rightsMetadata' datastream.  That datastream will be populated
   # by the unit.discoverability value, unless an discoverability value has already been designated to an object that will be created or updated which is
   # related to the Unit.  For example, if master_file.discoverability is designated before ingestion, the value of unit.discoverability will not be used; if
   # master_file.discoverability is not designated, the unit.discoverability value will be used to fill master_file.discoverability.

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

      # This should never fail becuase discoverability is checked at an earlier stage, but I will keep it here for sanity checking.
      if unit.master_file_discoverability.nil?
         on_error "Unit #{unit.id} has no discoverability value.  Please fill in and restart ingestion."
      else
         discoverability = unit.master_file_discoverability
      end

      if not object.discoverability
         object.discoverability = discoverability
         object.save!
         on_success "Discoverability for object #{object.class.name} #{object.id} is changed to #{discoverability}."
      else
         on_success "Discoverability for object #{object.class.name} #{object.id} is already set to #{object.discoverability} and will not be changed."
      end

      CreateNewFedoraObjects.exec_now({ :source => source, :object => object, :last => last }, self)
   end
end
