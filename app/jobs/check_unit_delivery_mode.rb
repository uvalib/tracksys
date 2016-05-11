class CheckUnitDeliveryMode < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)

      # Validate incoming messages
      raise "Parameter 'unit' is required" if message[:unit].blank?

      unit = message[:unit]
      unit.id = unit.id
      unit_dir = "%09d" % unit.id
      source_dir = File.join(IN_PROCESS_DIR, unit_dir)

      # The filter to determine which units get sent to repo must be worked on later at an appropriate time.
      if unit.include_in_dl and unit.availability_policy_id? and unit.intended_use.description == "Digital Collection Building"
         mode = "dl"
         on_success("Unit #{unit.id} requires the creation of repository deliverables.")
         CopyUnitForDeliverableGeneration.exec_now({ :unit => unit, :mode => mode, :source_dir => source_dir }, self)
      end

      if not unit.intended_use.description == "Digital Collection Building" and not unit.include_in_dl
         mode = "patron"
         on_success("Unit #{unit.id} requires the creation of patron deliverables.")
         CopyUnitForDeliverableGeneration.exec_now({ :unit => unit, :mode => mode, :source_dir => source_dir }, self)
      end

      if unit.include_in_dl and unit.availability_policy_id? and not unit.intended_use.description == "Digital Collection Building"
         mode = "both"
         on_success("Unit #{unit.id} requires the creation of patron deliverables.")
         CopyUnitForDeliverableGeneration.exec_now({ :unit => unit, :mode => mode, :source_dir => source_dir }, self)
      end

      # All units with no deliverables (either patron or DL) get sent to the archive at this step.
      if not unit.intended_use_deliverable_resolution and not unit.intended_use_deliverable_format and not unit.include_in_dl
         on_success "Unit #{unit.id} has no deliverables so is being sent directly to the archive."
         SendUnitToArchive.exec_now({ :unit => unit, :internal_dir => true, :source_dir => IN_PROCESS_DIR }, self)
      end
   end
end
