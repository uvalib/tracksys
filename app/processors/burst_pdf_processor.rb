class BurstPdfProcessor < ApplicationProcessor

  subscribes_to :burst_pdf, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :create_tif_images_from_pdf
  
  def on_message(message)  
    logger.debug "BurstPdfProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    @unit_id = hash[:unit_id]
    @unit_dir = "%09d" % @unit_id

    path_to_pdf = File.join(PRODUCTION_SCAN_DIR, "10_raw", "%09d" % @unit_id)
    pdf_file = "#{"%09d" % @unit_id}.pdf"
    complete_path = File.join(path_to_pdf, pdf_file)
    if File.exist?(complete_path)
      `pdftk  #{complete_path} burst output #{path_to_pdf}/#{@unit_dir}_%04d.pdf`
    else
      on_error "#{complete_path} does not exist."
    end
    
    message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :path_to_pdf => path_to_pdf })
    publish :create_tif_images_from_pdf, message
    on_success "PDF subdivided into individual PDFs successfully."        
  end
end
