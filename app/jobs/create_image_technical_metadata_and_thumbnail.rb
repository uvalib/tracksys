class CreateImageTechnicalMetadataAndThumbnail < BaseJob

   require 'exifr'
   require 'rmagick'

   def perform(message)
     Job_Log.debug "CreateImageTechnicalMetadataAndThumbnail received: #{message.to_s}"

     raise "Parameter 'master_file_id' is required" if message[:master_file_id].blank?
     raise "Parameter 'source' is required" if message[:source].blank?

     @messagable_id = message[:master_file_id]
     @messagable_type = "MasterFile"
     set_workflow_type()

     @source = message[:source]
     @master_file_id = message[:master_file_id]
     mf = MasterFile.find(@master_file_id)

     @image_path = @source

     # Open Rmagick and EXIFR objects for extraction of technical metadata.
     @image = Magick::Image.read("#{@image_path}").first
     @image_exif = EXIFR::TIFF.new("#{@image_path}")

     create_image_technical_metadata(mf)
     create_thumbnail(mf)

     # Make sure that the memory is cleared after the processor no longer needs these two objects.
     @image.destroy!
   end

   def create_image_technical_metadata(master_file)
     mf = master_file

     # Create new ImageTechMeta Object to store technical metadata for these image objects
     image_tech_meta = ImageTechMeta.new
     image_tech_meta.master_file = mf

     image_tech_meta.image_format = @image.format if @image.format
     image_tech_meta.width = @image_exif.width if @image_exif.width
     image_tech_meta.height = @image_exif.height if @image_exif.height
     image_tech_meta.resolution = @image_exif.x_resolution.to_i if @image_exif.x_resolution

     if @image.colorspace.to_s == 'RGBColorspace'
       image_tech_meta.color_space = 'RGB'
       image_tech_meta.depth = @image.depth * 3
     end

     if @image.compression.to_s == 'NoCompression'
       image_tech_meta.compression = 'Uncompressed'
     else
       image_tech_meta.compression = 'Compressed'
     end

     image_tech_meta.equipment = @image_exif.make if @image_exif.make
     image_tech_meta.software = @image_exif.software if @image_exif.software
     image_tech_meta.model = @image_exif.model if @image_exif.model
     image_tech_meta.capture_date = @image_exif.date_time_original if @image_exif.date_time_original
     image_tech_meta.iso = @image_exif.iso_speed_ratings if @image_exif.iso_speed_ratings
     image_tech_meta.exposure_bias = @image_exif.exposure_bias_value.to_i if @image_exif.exposure_bias_value
     image_tech_meta.exposure_time = @image_exif.exposure_time.to_s if @image_exif.exposure_time
     image_tech_meta.aperture = @image_exif.f_number.to_i if @image_exif.f_number
     image_tech_meta.focal_length = @image_exif.focal_length.to_s if @image_exif.focal_length
     image_tech_meta.exif_version = @image.get_exif_by_entry('ExifVersion')[0][1] if @image.get_exif_by_entry('ExifVersion')[0][1]
     mf.filesize = @image.filesize if @image.filesize
     mf.md5 = Digest::MD5.hexdigest(File.read("#{@image_path}"))

     # Pass the RMagick output of the 'color_profile' method so that it may be analyzed,
     # unpacked and queried for the color profile name.  Since this is a binary data
     # structure, the process is rather complicated
     if @image.color_profile
       image_tech_meta.color_profile = get_color_profile_name(@image.color_profile)
     end

     image_tech_meta.save!
     mf.save!
   end

   def get_color_profile_name(image_color_profile)
     profile = Array.new
     color_profile_name = String.new

     # Read the profile into an array
     image_color_profile.each_byte { |b| profile.push(b) }

     # Count the number of tags
     tag_count = profile[128,4].pack("c*").unpack("N").first

     # Find the "desc" tag
     tag_count.times do |i|
       n =  (128 + 4) + (12*i)
       ts = profile[n,4].pack("c*")
       if ts == 'desc'
         to = profile[n+4,4].pack("c*").unpack("N").first
         t_size = profile[n+8,4].pack("c*").unpack("N").first
         tag = profile[to,t_size].pack("c*").unpack("Z12 Z*")
         color_profile_name = tag[1].to_s
       end
     end

     return color_profile_name
   end

   def create_thumbnail(mf)
     unit_dir = "%09d" % mf.unit.id
     thumbnail = @image.resize_to_fit(1024,1024)

     # Get the contents of /digiserv-production/metadata and exclude directories that don't begin with and end with a number.  Hopefully this
     # will eliminate other directories that are of non-Tracksys managed content.
     @metadata_dir_contents = Dir.entries(PRODUCTION_METADATA_DIR).delete_if {|x| x == '.' or x == '..' or not /^[0-9](.*)[0-9]$/ =~ x}
     @metadata_dir_contents.each do |dir|
       @range = dir.split('-')
       if mf.unit.id.to_i.between?(@range.first.to_i, @range.last.to_i)
         @range_dir = dir
       end
    end

     if not File.exist?("#{PRODUCTION_METADATA_DIR}/#{@range_dir}/#{unit_dir}/Thumbnails_(#{unit_dir})")
       FileUtils.mkdir_p("#{PRODUCTION_METADATA_DIR}/#{@range_dir}/#{unit_dir}/Thumbnails_(#{unit_dir})")
     end

     thumbnail.write("#{PRODUCTION_METADATA_DIR}/#{@range_dir}/#{unit_dir}/Thumbnails_(#{unit_dir})/#{mf.filename.gsub(/tif/, 'jpg')}")
     thumbnail.destroy!
   end
end
