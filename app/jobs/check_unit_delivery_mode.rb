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


      # If OCR has been requested, do it AFTER archive (OCR requires tif to be in archive)
      # but before deliverable generation (deliverables require OCR text to be present)
      if unit.ocr_master_files
         OCR.synchronous(unit, self)
         unit.reload
      end

      # Figure out if this unit has any deliverables, and of what type
      # NOTE: no need to check avail policy. Prior jobs already enforce setting
      if unit.include_in_dl
         logger.info ("Unit #{unit.id} requires the creation of repository deliverables.")

         iiif_url = "#{Settings.iiif_manifest_url}/pid/#{unit.metadata.pid}?refresh=true"
         logger.info "Generating IIIF manifest with #{iiif_url}"
         resp = RestClient.get iiif_url
         if resp.code.to_i != 200
            logger.warn "Unable to generate IIIF manifest: #{resp.code}: #{resp.body}"
         else
            logger.info("IIIF manifest successfully generated")
         end

         PublishToDL.exec_now({unit_id: unit.id}, self)
      end

      # If desc is not digital collection building, create patron deliverables regardless of any other settings
      if unit.intended_use.description != "Digital Collection Building"
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
