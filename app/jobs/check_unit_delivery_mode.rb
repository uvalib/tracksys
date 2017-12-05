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
         check_auto_publish( unit )
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
         # default to first MF. This will be replaced below if a
         # suitable candidate is found. Preference: Front Cover, Title-page or 1
         exemplar = unit.master_files.first.filename
         unit.master_files.each do |mf|
            next if mf.title.blank?
            title = mf.title.strip
            if title == "Front Cover" || title == "Title-page" || title == "1"
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

   private
   def create_patron_deliverables(unit)
      logger.info("Unit #{unit.id} requires the creation of patron deliverables.")
      CreatePatronDeliverables.exec_now({ unit: unit }, self)
      CreateUnitZip.exec_now( { unit: unit }, self)
      CheckOrderReadyForDelivery.exec_now( { order_id: unit.order_id}, self  )
   end

   private
   def check_auto_publish(unit)
      logger.info "Checking unit #{unit.id} for auto-publish"
      if unit.complete_scan == false
         logger.info "Unit #{unit.id} is not a complete scan and cannot be auto-published"
         return
      end

      metadata = unit.metadata
      if metadata.is_manuscript || metadata.is_personal_item
         logger.info "Unit #{unit.id} is for a manuscript or personal item and cannot be auto-published"
         return
      end

      # TODO revisit this later; doesn't really make sense to only be sirsi published
      # but at the moment, that is all that CAN be published to virgo
      if metadata.type != "SirsiMetadata"
         logger.info "Unit #{unit.id} metadata is not from Sirsi and cannot be auto-published"
         return
      end

      # convert to SirsiMetadata so we can get at catalog_key and barcode.
      # Need this to check publication year before 1923
      sirsi_meta = metadata.becomes(SirsiMetadata)

      pub_info = Virgo.get_marc_publication_info(sirsi_meta.catalog_key, sirsi_meta.barcode)
      if !pub_info[:year].blank? && pub_info[:year].to_i < 1923
         logger.info "Unit #{unit.id} is a candidate for auto-publishing."
         # year is set and it is before 1923. Good to go for Autopublish.
         if sirsi_meta.availability_policy.nil?
            sirsi_meta.update(availability_policy_id: 1)
         end

         # update index and include_in_dl on unit if not set
         unit.update(include_in_dl: true)
         logger.info "Unit #{unit.id} successfully flagged for DL publication"

         # See if this is also eligable for DPLA (not hierarchical and public avail)
         if sirsi_meta.components.size == 0 && sirsi_meta.availability_policy_id == 1
            logger.info "Unit #{unit.id} is also acceptable for DPLA publishing"
            sirsi_meta.update(dpla: 1, parent_metadata_id: 15784)
         end
      else
         logger.info "Unit #{unit.id} has no date or a date after 1923 and cannot be auto-published"
      end
   end
end
