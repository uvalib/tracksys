class CreateTextFromPdfProcessor < ApplicationProcessor

  subscribes_to :create_text_from_pdf, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :create_master_file_records_from_tif_and_text
  
  def on_message(message)  
    logger.debug "CreateTextFromPdfProcessor received: " + message

    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    raise "Paramater 'path_to_pdf' is required" if hash[:path_to_pdf].blank?
    @unit_id = hash[:unit_id]
    @messagable_id = hash[:unit_id]
    @messagable_type = "Unit"
    @path_to_pdf = hash[:path_to_pdf]

    contents = Dir.entries(@path_to_pdf).delete_if {|x| x == "." or x == ".." or x !~ /_[0-9][0-9][0-9][0-9].pdf/}

    contents.each {|content|
      logger.debug "#{content}"
      basename = File.basename(File.join(@path_to_pdf, content), ".pdf")
      logger.debug "#{basename}"
      `pdftotext -layout #{@path_to_pdf}/#{content} #{@path_to_pdf}/#{basename}.txt`
    }

    message = ActiveSupport::JSON.encode({:unit_id => @unit_id, :path_to_pdf => @path_to_pdf})
    publish :create_master_file_records_from_tif_and_text, message
    on_success "Text files successfully created from PDF originals."        
  end
end
