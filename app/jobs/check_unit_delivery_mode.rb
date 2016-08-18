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
      has_deliverables = false

      # The filter to determine which units get sent to repo must be worked on later at an appropriate time.
      if unit.include_in_dl && unit.metadata.availability_policy_id? && unit.intended_use.description == "Digital Collection Building"
         has_deliverables = true
         mode = "dl"
         on_success("Unit #{unit.id} requires the creation of repository deliverables.")
         CopyUnitForDeliverableGeneration.exec_now({ :unit => unit, :mode => mode, :source_dir => source_dir }, self)
      end

      if not unit.intended_use.description == "Digital Collection Building" and not unit.include_in_dl
         has_deliverables = true
         mode = "patron"
         on_success("Unit #{unit.id} requires the creation of patron deliverables.")
         CopyUnitForDeliverableGeneration.exec_now({ :unit => unit, :mode => mode, :source_dir => source_dir }, self)
      end

      if unit.include_in_dl and unit.metadata.availability_policy_id? and not unit.intended_use.description == "Digital Collection Building"
         has_deliverables = true
         mode = "both"
         on_success("Unit #{unit.id} requires the creation of patron deliverables.")
         CopyUnitForDeliverableGeneration.exec_now({ :unit => unit, :mode => mode, :source_dir => source_dir }, self)
      end

      # All units with no deliverables (either patron or DL) get sent to IIIF and the archive now
      if has_deliverables == false
         on_success "Unit #{unit.id} has no deliverables so is being sent directly to IIIF and the archive."
         unit.master_files.each do |master_file|
            file_source = File.join(source_dir, master_file.filename)
            PublishToIiif.exec_now({ :source => file_source, :master_file_id=> master_file.id }, self)
         end
         SendUnitToArchive.exec_now({ :unit => unit, :internal_dir => true, :source_dir => IN_PROCESS_DIR }, self)
      end
   end
end
