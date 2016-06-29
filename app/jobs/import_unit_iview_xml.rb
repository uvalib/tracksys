class ImportUnitIviewXML < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'path' is required" if message[:path].blank?

      # Set unit variables
      unit = message[:unit]
      unit_dir = "%09d" % unit.id
      path = message[:path]

      # Import XML files
      xml_file = File.open(path.to_s)
      begin
         ImportIviewXml.import_iview_xml(xml_file, unit.id.to_s)
         xml_file.close
         logger().info( "Iview XML for Unit #{unit.id} successfully imported.")
      rescue Exception=>e
         on_error("Import Iview XML for Unit #{unit.id} FAILED: #{e.message}")
         xml_file.close
      end

      logger().info ("Beginning finalization...")
      unit.order.update_attribute(:date_finalization_begun, Time.now)
      logger().info("Date Finalization Begun updated for order #{unit.order.id}")

      CheckUnitDeliveryMode.exec_now({ :unit => unit }, self)
   end
end
