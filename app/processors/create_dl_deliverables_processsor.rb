class CreateDlDeliverablesProcessor < ApplicationProcessor

  require 'rubygems'
  require 'RMagick'

  subscribes_to :create_dl_deliverables, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :delete_unit_copy_for_deliverable_generation
  publishes_to :ingest_jp2k

  # Message can have these keys:
  # * pid - pid of the source image file
  # * source - full path to the source image file (master TIFF) to be
  #   processed
  # * mode - "dl", "dl-archive", "patron" or "both"
  # * format - "jpeg" or "tiff" (only applies when mode is "patron" or "both";
  #   defaults to "jpeg")
  # * order_id (only applies when mode is "patron" or "both")
  # * unit_id (only applies when mode is "patron" or "both")
  # * actual_resolution - resolution of master file (only applies when mode is
  #   "patron" or "both")
  # * desired_resolution - resolution requested by customer for deliverables
  #   (only applies when mode is "patron" or "both"; defaults to highest
  #   possible)
  # * last - If the master file is the last one for a unit, then this processor
  #   will send a message to the archive processor to archive the unit.
  # * remove_watermark - This option, set at the unit level, allows staff to
  #   to disable the inclusion of a watermark for the entire unit if the
  #   deliverable format is JPEG.
  #
  # Watermark Additions -
  # The following are n required and will only be used if format == 'jpeg'.
  # * call_number - If the item gets a watermark, this value will be added to the notice
  # * title - If the item gets a watermark, this value will be added to the notice.
  # * location - If the item gets a watermark, this value will be added to the notice.
  # * personal_item - If this is true, the watermark doesn't get written at all
  #
  # Most of these keys are optional, because there are reasonable defaults,
  # but "source" is always required; "pid" is required if mode is "dl", "dl-archive" or
  # "both"; order and unit numbers are required if mode is "patron" or "both".

  def on_message(message)
    logger.debug "CreateDlDeliverablesProcessor received: " + message.to_s

    hash = ActiveSupport::JSON.decode(message).symbolize_keys  # decode JSON message into Ruby hash
    raise "Parameter 'mode' is required" if hash[:mode].blank?
    raise "Parameter 'source' is required" if hash[:source].blank?
    raise "Parameter 'object_class' is required" if hash[:object_class].blank?
    raise "Parameter 'object_id' is required" if hash[:object_id].blank?

    @source = hash[:source]
    @mode = hash[:mode]
    @last = hash[:last]
    @object_class = hash[:object_class]
    @object_id = hash[:object_id]
    @object = @object_class.classify.constantize.find(@object_id)
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)
    @messagable_id = hash[:object_id]
    @messagable_type = hash[:object_class]

    @pid = @object.pid
    instance_variable_set("@#{@object.class.to_s.underscore}_id", @object_id)

    # Given the new requirment of recording md5 for MasterFile objects and the prohibition on downloading everything from
    # tape to record those md5's, we will take the opportunity here to record them as we pull them down from Stornext.
    #
    # Only do this if the md5 is empty and respect the old value.
    if @object.md5.nil?
      source_md5 = Digest::MD5.hexdigest(File.read(@source))
      @object.update_attributes(:md5 => source_md5)
    end

    if @object.is_a?(Tiff) or @object.filename.match(".tif$")
      # Introduce error handling for uncompressed images that kakadu will choke on.
      tiff = Magick::Image.read(@source).first
      @filesize = tiff.filesize
      unless tiff.compression.to_s == "NoCompression"
        tiff.compression=Magick::CompressionType.new("NoCompression", 1)
        tiff.write(@source)
        tiff.destroy!
        on_success "#{@object_class.to_s} #{@object_id} is compressed.  This has been corrected automatically.  Update MD5 for #{@source} if necessary."
      end

      tiff.destroy!
    end

    if @object.is_a?(JpegTwoThousand) or @object.filename.match(".jp2$")
      # write a JPEG-2000 file to the destination directory
      jp2k_filename = @object.pid.sub(/:/, '_') + '.jp2'
      jp2k_path = File.join(BASE_DESTINATION_PATH_DL, jp2k_filename)
      FileUtils.copy(@source, jp2k_path)

      # send message to tracksys ingest_jp2k_processor (so it can add jp2 deliverable as datastream for this object)
      message = ActiveSupport::JSON.encode( { :object_class => @object_class , :object_id => @object_id,  :jp2k_path => jp2k_path, :last => @last, :source => @source } )
      publish :ingest_jp2k, message
      on_success "Copied JPEG-2000 image using '#{@source}' as input file for the creation of deliverable '#{jp2k_path}'"

    elsif @source.match(/\.tiff?$/) and File.file?(@source)
      # Directly invoke Ruby's garbage collection to clear memory
      GC.start

      # generate deliverables for DL use
      # write a JPEG-2000 file to the destination directory
      jp2k_filename = @object.pid.sub(/:/, '_') + '.jp2'
      jp2k_path = File.join(BASE_DESTINATION_PATH_DL, jp2k_filename)

      # As per a conversation with Ethan Gruber, I'm dividing the JP2K compression ratios between images that are greater and less than 500MB.
      executable = KDU_COMPRESS || %x( which kdu_compress ).strip
      if File.exist? executable
         if @filesize > 524000000
           `#{executable} -i #{@source} -o #{jp2k_path} -rate 1.5 Clayers=20 Creversible=yes Clevels=8 Cprecincts="{256,256},{256,256},{128,128}" Corder=RPCL ORGgen_plt=yes ORGtparts=R Cblk="{32,32}" -num_threads #{NUM_JP2K_THREADS}`
         else
           `#{executable} -i #{@source} -o #{jp2k_path} -rate 1.0,0.5,0.25 -num_threads #{NUM_JP2K_THREADS}`
         end
      else
         puts "NO KDU COMPRESS; TRY IMAGEMAGICK"
         #  `cp #{@source} #{jp2k_path}`
         `/usr/local/bin/convert #{@source} -quiet -compress JPEG2000 -quality 75 -define jp2:rate=1.5 #{jp2k_path}`
         #on_failure "KDU_COMPRESS #{executable} does not exist, fallback to imagemagick convert!"
      end

      # send message to tracksys ingest_jp2k_processor (so it can add jp2 deliverable as datastream for this object)
      message = ActiveSupport::JSON.encode( { :object_class => @object_class , :object_id => @object_id,  :jp2k_path => jp2k_path, :last => @last, :source => @source } )
      publish :ingest_jp2k, message
      on_success "Generated JPEG-2000 image using '#{@source}' as input file for the creation of deliverable '#{jp2k_path}'"

      # Got to put in a success message here!
    else
      raise "Source is not a .tif file: #{@source}"
    end
  end
end
