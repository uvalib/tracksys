class ImportUnitIviewXML < BaseJob

   def perform(message)
      Job_Log.debug "ImportUnitIviewXMLProcessor received: #{message.to_json}"

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'path' is required" if message[:path].blank?

      # Set unit variables
      @unit_id = message[:unit_id]
      @messagable_id = message[:unit_id]
      @messagable_type = "Unit"
      set_workflow_type()
      @unit_dir = "%09d" % @unit_id
      @path = message[:path]

      # Import XML files
      xml_file = File.open(@path.to_s)
      ImportIviewXml.import_iview_xml(xml_file, @unit_id.to_s)
      xml_file.close
      on_success "Iview XML for Unit #{@unit_id} successfully imported."

      # copy metadata first because the finalization process will move the
      # data from in-process to ready-to-delete, causing the metadata copy to fail
      unit_path = File.join(IN_PROCESS_DIR, @unit_dir)
      Job_Log.debug ("Copying metadata for unit #{@unit_id} from #{unit_path}")
      CopyMetadataToMetadataDirectory.exec_now({ :unit_id => @unit_id, :unit_path => unit_path })

      Job_Log.debug ("Beginning finalization...")
      UpdateOrderDateFinalizationBegun.exec_now({ :unit_id => @unit_id })
   end
end
