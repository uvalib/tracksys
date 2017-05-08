class CheckUnitDeliveryMode < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)

      # Validate incoming messages
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      unit = Unit.find(message[:unit_id])
      logger.info "Source Unit: #{unit.to_json}"
      unit.id = unit.id
      unit_dir = "%09d" % unit.id
      source_dir = File.join(IN_PROCESS_DIR, unit_dir)
      has_deliverables = false

      # First, check if this unit is a candidate for Autopublish to Virgo
      if unit.include_in_dl == false && unit.reorder == false
         CheckAutoPublish.exec_now({:unit => unit}, self)
      end

      if unit.reorder? && unit.include_in_dl
         on_failure("Reorders can not be sent to DL. resetting include_in_dl to false")
         unit.update(include_in_dl: false)
      end

      if unit.include_in_dl && unit.metadata.availability_policy_id.blank?
         # stop processing if availability policy is not set
         on_error("Availability policy must be set for all units flagged for inclusion in the DL")
      end

      # Make sure an exemplar is picked if flagged for DL
      if unit.include_in_dl == true && unit.metadata.type == "SirsiMetadata" && unit.metadata.exemplar.blank?
         logger.info "Exemplar is blank; looking for a default"
         exemplar = nil
         unit.master_files.each do |mf|
            exemplar = mf.filename if exemplar.nil?
            if !mf.title.blank? && mf.title.strip == "1"
               exemplar = mf.filename
               break
            end
         end
         if !exemplar.blank?
            logger.info "Defaulting exemplar to #{exemplar}"
            unit.metadata.update(exemplar: exemplar)
         end
      end

      # Figure out if this unit has any deliverables, and of what type...
      if unit.include_in_dl && unit.metadata.availability_policy_id? && unit.intended_use.description == "Digital Collection Building"
         has_deliverables = true
         mode = "dl"
         on_success("Unit #{unit.id} requires the creation of repository deliverables.")
         CopyUnitForDeliverableGeneration.exec_now({ :unit => unit, :mode => mode, :source_dir => source_dir }, self)
      end

      if unit.intended_use.description != "Digital Collection Building" && unit.include_in_dl == false
         has_deliverables = true
         mode = "patron"
         on_success("Unit #{unit.id} requires the creation of patron deliverables.")
         CopyUnitForDeliverableGeneration.exec_now({ :unit => unit, :mode => mode, :source_dir => source_dir }, self)
      end

      if unit.include_in_dl && unit.metadata.availability_policy_id? && unit.intended_use.description != "Digital Collection Building"
         has_deliverables = true
         mode = "both"
         on_success("Unit #{unit.id} requires the creation of patron deliverables.")
         CopyUnitForDeliverableGeneration.exec_now({ :unit => unit, :mode => mode, :source_dir => source_dir }, self)
      end

      # All units with no deliverables (either patron or DL) get sent to IIIF and the archive now
      # ...unless the unit is a re-order. These never go to IIIF or archive
      if has_deliverables == false && unit.reorder == false
         on_success "Unit #{unit.id} has no deliverables so is being sent directly to IIIF and the archive."
         unit.master_files.each do |master_file|
            file_source = File.join(source_dir, master_file.filename)
            PublishToIiif.exec_now({ :source => file_source, :master_file_id=> master_file.id }, self)
         end
         SendUnitToArchive.exec_now({ :unit => unit, :internal_dir => true, :source_dir => IN_PROCESS_DIR }, self)
      end
   end
end
