class CheckAutoPublish < BaseJob

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      unit = message[:unit]
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
         logger.info "Unit #{unit.id} is a candidate for auto-publishing. Updating attributes..."
         # year is set and it is before 1923. Good to go for Autopublish.
         # Ensure indexing and availability are all set correctly
         if sirsi_meta.indexing_scenario.nil?
            sirsi_meta.update(indexing_scenario_id: 1)
         end
         if sirsi_meta.availability_policy.nil?
            sirsi_meta.update(availability_policy_id: 1)
         end

         # update index and include_in_dl on unit if not set
         unit.update(include_in_dl: true, master_file_discoverability: true)
         if unit.indexing_scenario.nil?
            unit.update(indexing_scenario_id: 1)
         end

         # update master file index scenario, use right (if not set) and date_dl_ingest
         unit.master_files.each do |mf|
            mf.update(indexing_scenario_id: 1) if mf.indexing_scenario_id.blank?
            mf.update(use_right_id: 2) if mf.use_right_id.blank?
         end
         logger.info "Unit #{unit.id} successfully flagged for publication"
      else
         logger.info "Unit #{unit.id} has no date or a date after 1923 and cannot be auto-published"
      end
   end
end