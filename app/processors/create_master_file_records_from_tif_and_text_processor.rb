class CreateMasterFileRecordsFromTifAndTextProcessor < ApplicationProcessor

  require 'rubygems'
  require 'RMagick'

  subscribes_to :create_master_file_records_from_tif_and_text, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :send_pdf_unit_to_finalization_dir
  
  def on_message(message)  
    logger.debug "CreateMasterFileRecordsFromTifAndTextProcessor received: " + message

    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    raise "Paramater 'path_to_pdf' is required" if hash[:path_to_pdf].blank?
    @unit_id = hash[:unit_id]
    @unit_dir = "%09d" % @unit_id
    @messagable = Unit.find(@unit_id)
    @path_to_pdf = hash[:path_to_pdf]
 
    # The variable i will be used to pull out specific elements from the titles array for use in mf.title
    i = 0

    contents = Dir.entries(@path_to_pdf).delete_if {|x| x == "." or x == ".." or x !~ /_[0-9][0-9][0-9][0-9].tif/}
    title_file = File.read(File.join(@path_to_pdf, "#{@unit_dir}_titles.txt"))
    titles = title_file.split("\n")

    if contents.length != titles.length
      on_error "The number of TIF images does not equal the number of strings to be used as titles in the master file record.  Check #{@unit_dir}_titles.txt."
    end

    contents.each {|content|
      logger.debug "#{content}"
      basename = File.basename(File.join(@path_to_pdf, content), ".tif")
      logger.debug "#{basename}"

      tiff = Magick::Image.read(File.join(@path_to_pdf, content)).first
      transcription_text = File.read(File.join(@path_to_pdf, "#{basename}.txt"))

      mf = MasterFile.new
      mf.unit_id = @unit_id
      mf.tech_meta_type = "image"
      mf.filename = content
      mf.filesize = tiff.filesize
      mf.name_num = titles[i]
      mf.transcription_text = transcription_text.gsub(/\f/, '')
      mf.save!

      image_tech_meta = ImageTechMeta.new
      image_tech_meta.master_file_id = mf.id
      image_tech_meta.image_format = tiff.format
      image_tech_meta.width = tiff.columns
      image_tech_meta.height = tiff.rows
      image_tech_meta.resolution = tiff.x_resolution.to_i
      image_tech_meta.resolution_unit = "dpi"
      image_tech_meta.color_space = "GRAY"
      image_tech_meta.depth = tiff.depth
      image_tech_meta.compression = "Uncompressed"
      image_tech_meta.software = tiff.properties.values_at("tiff:software").first

      image_tech_meta.save!
      i += 1
    }

    message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :path_to_pdf => @path_to_pdf})
    
    publish :send_pdf_unit_to_finalization_dir, message
    on_success "Master File records successfully created for unit #{@unit_id}.  Sending unit to #{IN_PROCESS_DIR}."        
  end
end
