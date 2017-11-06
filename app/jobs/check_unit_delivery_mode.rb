class CheckUnitDeliveryMode < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      unit = Unit.find(message[:unit_id])
      logger.info "Source Unit: #{unit.to_json}"

      # First, check if this unit is a candidate for Autopublish to Virgo
      if unit.include_in_dl == false && unit.reorder == false
         CheckAutoPublish.exec_now({:unit => unit}, self)
      end

      # Reorders can't got to DL. Update flag accordingly
      if unit.reorder? && unit.include_in_dl
         on_failure("Reorders can not be sent to DL. resetting include_in_dl to false")
         unit.update(include_in_dl: false)
      end

      # Stop processing if availability policy is not set
      if unit.include_in_dl && unit.metadata.availability_policy_id.blank?
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

      # Copy all masterfiles to processing and flatten directories if they exist.
      # This gives a common start point for all further processing
      CopyUnitForProcessing.exec_now({ :unit => unit}, self)
      processing_dir = Finder.finalization_dir(unit, :process_deliverables)

      # Regardless of the use, ALL masterfiles coming into tracksys must be sent to IIIF.
      # Exception: reorders. These masterfile are already in IIIF and shouldn't be re-added.
      if unit.reorder == false
         unit.master_files.each do |master_file|
            file_source = File.join(processing_dir, master_file.filename)
            PublishToIiif.exec_now({ :source => file_source, :master_file_id=> master_file.id }, self)
         end
      end

      if unit.ocr_master_files
         Ocr.exec_now({object_class: "Unit", object_id: unit.id,
            language: unit.metadata.ocr_language_hint, exclude: []}, self)
      end

      # Figure out if this unit has any deliverables, and of what type:
      if unit.include_in_dl && unit.metadata.availability_policy_id?
         # flagged for DL and policy set. Send to DL
         logger.info ("Unit #{unit.id} requires the creation of repository deliverables.")
         PublishToDL.exec_now({unit_id: unit.id}, self)
         if unit.intended_use.description != "Digital Collection Building"
            create_patron_deliverables(unit)
         end
      end

      if unit.intended_use.description != "Digital Collection Building" && unit.include_in_dl == false
         create_patron_deliverables(unit)
      end

      logger.info "Processing complete; removing processing diectory: #{processing_dir}"
      FileUtils.rm_rf(processing_dir)

      # All units except re-orders go to archive
      if unit.reorder == false
         # Archive the unit and move in_process files to ready_to_delete
         SendUnitToArchive.exec_now({ :unit_id => unit.id }, self)
      else
         logger.info "Cleaning up in_process files for completed re-order"
         MoveCompletedDirectoryToDeleteDirectory.exec_now({ unit_id: unit.id, source_dir: Finder.finalization_dir(unit, :in_process)}, self)
      end
   end

   def create_patron_deliverables(unit)
      logger.info("Unit #{unit.id} requires the creation of patron deliverables.")
      CreatePatronDeliverables.exec_now({ unit: unit }, self)
      CreateUnitZip.exec_now( { unit: unit }, self)
      CheckOrderReadyForDelivery.exec_now( { order_id: unit.order_id}, self  )
   end
end
