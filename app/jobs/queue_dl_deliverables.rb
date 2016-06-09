class QueueDlDeliverables < BaseJob

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'source' is required" if message[:source].blank?

      unit = message[:unit]
      source = message[:source]

      # get a list of all items related to this unit
      # Always add a unit's Bibl, master files and components (and their ancestors)
      things = [unit.bibl]
      unit.master_files.each {|mf| things << mf }
      unit.components.each do |component|
         things << component
         # the following may produce duplicates, especially when ingesting many items from the same
         # EAD guide, so we must uniq them before emitting messages (as done four lines below).
         things << component.ancestors
      end

      things.flatten!
      things.uniq.each do |thing|

         # LFF Don't send the top-level Daily Progress component or bibl
         if thing.pid == "uva-lib:2137307" || thing.pid == "uva-lib:2065830"
            logger.info "Skipping Daily Progress top-level component/bibl (pid: #{thing.pid})"
            next
         end

         # Propogate attributes, then fan out and create deliverables
         PropogateDlAttributes.exec_now({:unit => unit, :source => source, :object => thing }, self)
      end

      # All deliverables generated; update timestamp and cleanup
      unit.update_attribute(:date_dl_deliverables_ready, Time.now)
      logger.info "Unit #{unit.id} is ready for ingestion into the DL."

      if source.match("#{FINALIZATION_DIR_MIGRATION}") or source.match("#{FINALIZATION_DIR_PRODUCTION}")
         del_dir = File.dirname(source)
         logger().debug("Removing processing directory #{del_dir}/...")
         FileUtils.rm_rf(del_dir)
         logger.info("Files for unit #{unit.id} copied for the creation of #{@dl} deliverables have now been deleted.")
      end

   end
end
