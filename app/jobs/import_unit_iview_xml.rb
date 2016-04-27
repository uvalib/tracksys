class ImportUnitIviewXML < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'path' is required" if message[:path].blank?

      # Set unit variables
      @unit_id = message[:unit_id]
      @unit_dir = "%09d" % @unit_id
      @path = message[:path]
      @unit = Unit.find(@unit_id)

      # Import XML files
      xml_file = File.open(@path.to_s)
      begin
         ImportIviewXml.import_iview_xml(xml_file, @unit_id.to_s)
         xml_file.close
         logger().info( "Iview XML for Unit #{@unit_id} successfully imported.")
      rescue Exception=>e
         on_error("Import Iview XML for Unit #{@unit_id} FAILED: #{e.message}")
         xml_file.close
      end

      # copy metadata first because the finalization process will move the
      # data from in-process to ready-to-delete, causing the metadata copy to fail
      unit_path = File.join(IN_PROCESS_DIR, @unit_dir)
      logger().info ("Copying metadata for unit #{@unit_id} from #{unit_path}")
      CopyMetadataToMetadataDirectory.exec_now({ :unit_id => @unit_id, :unit_path => unit_path }, self)

      logger().info ("Beginning finalization...")
      @unit.order.update_attribute(:date_finalization_begun, Time.now)
      logger().info("Date Finalization Begun updated for order #{@unit.order.id}")

      CheckUnitDeliveryMode.exec_now({ :unit_id => @unit_id }, self)
   end
end
