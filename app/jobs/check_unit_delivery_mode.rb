class CheckUnitDeliveryMode < BaseJob

   def perform(message)
      Job_Log.debug "CheckUnitDeliveryModeProcessor received: #{message.to_json}"

      # Validate incoming messages
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      @unit_id = message[:unit_id]
      @working_unit = Unit.find(@unit_id)
      @messagable_id = message[:unit_id]
      @messagable_type = "Unit"
      set_workflow_type()
      @unit_dir = "%09d" % @unit_id

      @source_dir = File.join(IN_PROCESS_DIR, @unit_dir)

      # The filter to determine which units get sent to repo must be worked on later at an appropriate time.
      if @working_unit.include_in_dl and @working_unit.availability_policy_id? and @working_unit.intended_use.description == "Digital Collection Building"
         @mode = "dl"
         CopyUnitForDeliverableGeneration.exec_now({ :unit_id => @unit_id, :mode => @mode, :source_dir => @source_dir })
         on_success("Unit #{@unit_id} requires the creation of repository deliverables.")
      end

      if not @working_unit.intended_use.description == "Digital Collection Building" and not @working_unit.include_in_dl
         @mode = "patron"
         on_success("Unit #{@unit_id} requires the creation of patron deliverables.")
         CopyUnitForDeliverableGeneration.exec_now({ :unit_id => @unit_id, :mode => @mode, :source_dir => @source_dir })
      end

      if @working_unit.include_in_dl and @working_unit.availability_policy_id? and not @working_unit.intended_use.description == "Digital Collection Building"
         @mode = "both"
         on_success("Unit #{@unit_id} requires the creation of patron deliverables.")
         CopyUnitForDeliverableGeneration.exec_now({ :unit_id => @unit_id, :mode => @mode, :source_dir => @source_dir })
      end

      # All units with no deliverables (either patron or DL) get sent to the archive at this step.
      if not @working_unit.intended_use_deliverable_resolution and not @working_unit.intended_use_deliverable_format and not @working_unit.include_in_dl
         on_success "Unit #{@unit_id} has no deliverables so is being sent directly to the archive."
         SendUnitToArchive.exec_now({ :unit_id => @unit_id, :internal_dir => 'yes', :source_dir => IN_PROCESS_DIR })
      end
   end
end
