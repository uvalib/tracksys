class CheckUnitDeliveryMode < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      unit = Unit.find(message[:unit_id])
      logger.info "Source Unit: #{unit.to_json}"

      # Make sure an exemplar is picked if flagged for DL
      if unit.include_in_dl == true && unit.metadata.has_exemplar? == false
         logger.info "Exemplar is blank; selecting a default..."
         # Pick a suitable candidate. Preference: Front Cover, Title-page or 1.
         # Failing that, something kinda square-sh (not super tall and thin or short and wide)
         # If nothing else works, choose first
         exemplar = unit.pick_exemplar
         logger.info "Defaulting exemplar to #{exemplar}"
      end

      # Copy all masterfiles to processing and flatten directories if they exist.
      # This gives a common start point for all further processing
      CopyUnitForProcessing.exec_now({ :unit => unit}, self)
      processing_dir = Finder.finalization_dir(unit, :process_deliverables)

      # Regardless of the use, ALL masterfiles coming into tracksys must be sent to IIIF.
      # Exception: reorders. These masterfile are already in IIIF and shouldn't be re-added.
      if unit.reorder == false
         logger.info("Publishing #{unit.master_files.count} to IIIF...")
         cnt = 0
         unit.master_files.each do |master_file|
            file_source = File.join(processing_dir, master_file.filename)
            PublishToIiif.exec_now({ :source => file_source, :master_file_id=> master_file.id }, self)
            cnt += 1
         end
         logger.debug("#{cnt} master files published to IIIF")
         if cnt != unit.master_files.count
            fatal_error "Mismatch in count of master files published to IIIF"
         end
      end

      # All non-reorder, non-throw away units go to the archive
      if unit.reorder == false && unit.throw_away == false
         SendUnitToArchive.exec_now({ :unit_id => unit.id }, self)
      end

      # If OCR has been requested, do it AFTER archive (OCR requires tif to be in archive)
      # but before deliverable generation (deliverables require OCR text to be present)
      if unit.ocr_master_files
         OCR.synchronous(unit, self)
         unit.reload
      end

      # Figure out if this unit has any deliverables, and of what type:
      if unit.include_in_dl && unit.metadata.availability_policy_id?
         # flagged for DL and policy set. Send to DL
         logger.info ("Unit #{unit.id} requires the creation of repository deliverables.")
         PublishToDL.exec_now({unit_id: unit.id}, self)
         if unit.intended_use.description != "Digital Collection Building"
            create_patron_deliverables(unit)
         end

         # If this unit is also slated for DPLA, publish the QDC
         if unit.metadata.in_dpla?
            logger.info "This unit is to be available in DPLA. Generate and publish QDC."
            PublishQDC.exec_now({metadata_id: unit.metadata_id})
         end
      end

      if unit.intended_use.description != "Digital Collection Building" && unit.include_in_dl == false
         create_patron_deliverables(unit)
      end

      logger.info "Processing complete; removing processing directory: #{processing_dir}"
      FileUtils.rm_rf(processing_dir)

      # See if the unit should be published to AS
      if unit.metadata.type == "ExternalMetadata" && unit.metadata.external_system.name == "ArchivesSpace" && unit.throw_away == false
         PublishToAS.exec_now({metadata: unit.metadata})
      end
      
      # All done; in_process files can go to ready_to_delete
      logger.info "Cleaning up in_process files for completed re-order"
      MoveCompletedDirectoryToDeleteDirectory.exec_now({ unit_id: unit.id, source_dir: Finder.finalization_dir(unit, :in_process)}, self)
   end

   def create_patron_deliverables(unit)
      if unit.intended_use.deliverable_format == "pdf"
         logger.info("Unit #{unit.id} requires the creation of PDF patron deliverables.")
         CreatePDFDeliverable.exec_now({ unit: unit }, self)
      else
         logger.info("Unit #{unit.id} requires the creation of patron deliverables.")
         CreatePatronDeliverables.exec_now({ unit: unit }, self)
         CreateUnitZip.exec_now( { unit: unit }, self)
      end

      # check for completeness, fees and generate manifest PDF. Same for all
      # patron deliverables
      CheckOrderReadyForDelivery.exec_now( { order_id: unit.order_id}, self  )
   end
end
