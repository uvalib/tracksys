class QaUnitData < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      # If this Unit.find fails, a unit with this id does not exist in Tracksys
      unit = Unit.find(message[:unit_id])
      logger.info "Source Unit: #{unit.to_json}"
      order = unit.order

      # Create error message holder array
      failure_messages = Array.new

      #-------------------------
      # QA Logic
      #-------------------------

      # First, check if unit is assigned to metadata record. This is an immediate fail
      if unit.metadata.nil?
         fatal_error "Unit #{unit.id} is not assigned to a metadata record."
      end

      # Is this unit is a candidate for Autopublish?
      if unit.include_in_dl == false && unit.reorder == false
         check_auto_publish( unit )
      end

      # Reorders can't got to DL. Update flag accordingly
      if unit.reorder? && unit.include_in_dl
         log_failure("Reorders cannot be sent to DL. Resetting include_in_dl to false")
         unit.update(include_in_dl: false)
      end

      # Stop processing if availability policy is not set for non-external metadata
      if unit.include_in_dl && unit.metadata.availability_policy_id.blank? && unit.metadata.type != "ExternalMetadata"
         failure_messages << "Availability policy must be set for all units flagged for inclusion in the DL"
      end

      # Fail if unit.date_patron_deliverables_ready is already filled out
      if unit.date_patron_deliverables_ready
         failure_messages << "Unit #{unit.id} already has a value for date_patron_deliverables_ready."
      end

      # Fail if unit.date_dl_deliverables_ready is already filled out
      if unit.date_dl_deliverables_ready
         failure_messages << "Unit #{unit.id} already has a value for date_dl_deliverables_ready."
      end

      # Must have a unit status, and it must be approved
      if unit.unit_status != "approved"
         failure_messages << "Unit #{unit.id} has not been approved."
      end

      # Fail if unit.intended_use is blank
      if not unit.intended_use
         failure_messages << "Unit #{unit.id} has no intended use.  All units that participate in this workflow must have an intended use."
      end

      # fail for no ocr hint or incompatible hint / ocr Settings
      if unit.metadata.ocr_hint_id.nil?
         failure_messages << "Unit metadata #{unit.metadata.id} has no OCR Hint. This is a required setting."
      else
         if unit.ocr_master_files
            if !unit.metadata.ocr_hint.ocr_candidate
               failure_messages << "Unit is flagged to perform OCR, but the metadata setting indicates OCR is not possible. "
            end
            if unit.metadata.ocr_language_hint.nil?
               failure_messages << "Unit is flagged to perform OCR, but the required language hint for metadata #{unit.metadata.id} is not set"
            end
         end
      end

      if unit.include_in_dl && unit.throw_away
         failure_messages << "Throw away units cannot be flagged for publication to the DL. "
      end

      # In response to DSSR staff's inconsistent use of the date_approved field, this logic will now warn but enforce the inclusion of a date_approved value.
      if not order.date_order_approved?
         # Define and undefine @order_id within this conditional to ensure that only this message is attached to the Order.
         logger.info "Order #{order.id} is not marked as approved.  Since this unit is undergoing finalization, the workflow has automatically updated this value and changed the order_status to approved."
         order.date_order_approved = Time.now
         order.order_status = 'approved'
         if !order.save
            fatal_error( order.errors.full_messages.to_sentence )
         end
      end

      #-------------------------
      # Failure Message Handling
      #-------------------------

      if failure_messages.empty?
         on_success "Unit #{unit.id} has passed the QaUnitDataProcessor."
         QaFilesystemAndIviewXml.exec_now( { :unit_id => unit.id }, self)
      else
         failure_messages.each do |message|
            log_failure message
            if message == failure_messages.last
               fatal_error "Unit #{unit.id} has failed the QA Unit Data Processor"
            end
         end
      end
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
