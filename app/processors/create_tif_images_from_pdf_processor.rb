class CreateTifImagesFromPdfProcessor < ApplicationProcessor

  subscribes_to :create_tif_images_from_pdf, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :create_text_from_pdf
  
  def on_message(message)  
    logger.debug "CreateTifImagesFromPdfProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    raise "Paramater 'path_to_pdf' is required" if hash[:path_to_pdf].blank?
    @unit_id = hash[:unit_id]
    @path_to_pdf = hash[:path_to_pdf]

    contents = Dir.entries(@path_to_pdf).delete_if {|x| x == "." or x == ".." or x !~ /_[0-9][0-9][0-9][0-9].pdf/}

    contents.each {|content|
      logger.debug "#{content}"
      basename = File.basename(File.join(@path_to_pdf, content), ".pdf")
      logger.debug "#{basename}"
      `convert -format tif -density 300 -depth 8 -colorspace Gray #{@path_to_pdf}/#{content} #{@path_to_pdf}/#{basename}.tif`
    }

    message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :path_to_pdf => @path_to_pdf })
    publish :create_text_from_pdf, message
    on_success "TIF images succesfully created from PDF originals."        
  end
end
