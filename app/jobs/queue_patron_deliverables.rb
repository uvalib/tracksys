class QueuePatronDeliverables < BaseJob

   def do_workflow(message)

      # Validate incoming messages
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'source' is required" if message[:source].blank?

      unit = message[:unit]
      source = message[:source]
      # NOTES: in this case source is File.join(PROCESS_DELIVERABLES_DIR, 'patron', unit_dir)
      # where unit_dir is the 9-digit, 0-padded unit ID

      unit.master_files.each do |master_file|
         # Ensure that master file has a pid
         if master_file.pid.nil?
            master_file.pid = AssignPids.get_pid
            master_file.save!
         end

         file_source = File.join(source, master_file.filename)
         CreatePatronDeliverables.exec_now({ :master_file_id => master_file.id,
            :source => file_source, :format => unit.intended_use_deliverable_format,
            :actual_resolution => master_file.image_tech_meta.resolution,
            :desired_resolution => unit.intended_use_deliverable_resolution,
            :unit_id => unit.id, :personal_item => unit.bibl.personal_item?,
            :call_number => unit.bibl.call_number, :title => unit.bibl.title,
            :location => unit.bibl.location, :remove_watermark => unit.remove_watermark}, self)
      end

      logger().info("All patron deliverables created")
      logger().info("Removing patron processing directory: #{source}")
      FileUtils.rm_rf(source)
      logger().info("Files for unit #{unit.id} copied for the creation of patron deliverables have now been deleted.")

      unit.update_attribute(:date_patron_deliverables_ready, Time.now)
      logger().info("Date patron deliverables ready for unit #{unit.id} has been updated.")
      CheckOrderReadyForDelivery.exec_now( { :order => unit.order, :unit_id => unit.id }, self  )
   end
end
