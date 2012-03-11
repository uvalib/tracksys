class SendPdfUnitToFinalizationDirProcessor < ApplicationProcessor
   
  require 'fileutils'

  subscribes_to :send_pdf_unit_to_finalization_dir, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :check_unit_delivery_mode
  
  def on_message(message)  
    logger.debug "SendPDFUnitToFinalizationDirProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    raise "Paramater 'path_to_pdf' is required" if hash[:path_to_pdf].blank?
    @unit_id = hash[:unit_id]
    @messagable = Unit.find(@unit_id)
    @unit_dir = "%09d" % @unit_id
    @path_to_pdf = hash[:path_to_pdf]

    FileUtils.mv File.join(@path_to_pdf), File.join(IN_PROCESS_DIR, @unit_dir)

    message = ActiveSupport::JSON.encode({ :unit_id => @unit_id })
    publish :check_unit_delivery_mode, message
    on_success "#{@unit_dir} moved to #{IN_PROCESS_DIR}"        
  end
end
