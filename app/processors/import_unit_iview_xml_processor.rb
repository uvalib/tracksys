class ImportUnitIviewXMLProcessor < ApplicationProcessor  # See ApplicationProcessor for error handling

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :import_unit_iview_xml, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :update_order_date_finalization_begun
  publishes_to :copy_metadata_to_metadata_directory
  
  def on_message(message)
    logger.debug "ImportUnitIviewXMLProcessor received: " + message

    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Validate incoming message
    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank? 
    raise "Parameter 'path' is required" if hash[:path].blank? 

    # Set unit variables
    @unit_id = hash[:unit_id]
    @messagable = Unit.find(@unit_id)
    @unit_dir = "%09d" % @unit_id
    @path = hash[:path]
    
    # Import XML files
    xml_file = File.open(@path.to_s)  
    ImportIviewXml.import_iview_xml(xml_file, @unit_id.to_s)
    xml_file.close
    # Introduce logic to prevent the messages from being sent if there are errors on import.

    # Publish message
    message = ActiveSupport::JSON.encode({ :unit_id => @unit_id })
    publish :update_order_date_finalization_begun, message  

    unit_path = File.join(IN_PROCESS_DIR, @unit_dir)
    message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :unit_path => unit_path })
    publish :copy_metadata_to_metadata_directory, message

    on_success "Iview XML for Unit #{@unit_id} successfully imported."        
  end
end
