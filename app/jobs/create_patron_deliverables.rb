class CreatePatronDeliverables < BaseJob

   require 'rmagick'

   #
   # Note: this should always be called with masterfiles in the PROCESSING directory
   #
   def do_workflow(message)
      unit = message[:unit]

      # if a prior set of deliveranbles is in the assembly dir, remove them
      # Note: this dir includes order_####
      assemble_dir = Finder.finalization_dir(unit, :assemble_deliverables)
      if Dir.exist? assemble_dir
         logger.info "Removing old deliverables from assembly directory #{assemble_dir}"
         FileUtils.rm_rf(assemble_dir)
      end
      FileUtils.mkdir_p(assemble_dir)

      processing_dir = Finder.finalization_dir(unit, :process_deliverables)
      unit.master_files.each do |master_file|
         file_source = File.join(processing_dir, master_file.filename)
         logger.info "Create deliverable for MasterFile #{master_file_id} from #{file_source}"
         Patron.create_deliverable(unit, master_file, file_source, assemble_dir)
         logger.info "Deliverable image created at #{dest_path}"
      end

      unit.update(date_patron_deliverables_ready: Time.now)
      logger.info("All patron deliverables created")
   end
end
