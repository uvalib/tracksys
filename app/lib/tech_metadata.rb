module TechMetadata
   # Create image tech metadata
   def self.create(master_file, image_path)
      image = MiniMagick::Image.open(image_path)
      data = image.data

      image_tech_meta = ImageTechMeta.new
      image_tech_meta.master_file = master_file
      image_tech_meta.image_format = data["format"]

      if data['colorspace'] == 'RGBColorspace' || data['colorspace'] == "sRGB"
         image_tech_meta.color_space = 'RGB'
         image_tech_meta.depth = data['depth'] * 3
      end

      if data['compression'] == 'None'
         image_tech_meta.compression = 'Uncompressed'
      else
         image_tech_meta.compression = 'Compressed'
      end

      # Extract ICC profile description with exiftool. Out format is:
      # "Profile Description             : Adobe RGB (1998)\n"
      cmd = "exiftool -icc_profile:ProfileDescription #{image_path}"
      info = `#{cmd}`
      if !info.blank?
         image_tech_meta.color_profile = info.split(":")[1].strip
      end

      image_tech_meta.width = data['geometry']['width'] if !data['geometry'].blank?
      image_tech_meta.height = data['geometry']['height'] if !data['geometry'].blank?
      image_tech_meta.resolution = data['resolution']['x'] if !data['resolution'].blank?
      props = data['properties']
      if !props.blank?
         image_tech_meta.equipment = props['tiff:make']
         image_tech_meta.software = props['tiff:software']
         image_tech_meta.model = props['tiff:model']
         if !props['exif:DateTimeOriginal'].blank?
            image_tech_meta.capture_date = props['exif:DateTimeOriginal'].split(":",3).join("/").to_datetime
         end
         image_tech_meta.iso = props['exif:ISOSpeedRatings']
         image_tech_meta.exposure_bias = props['exif:ExposureBiasValue']
         image_tech_meta.exposure_time = props['exif:ExposureTime']
         image_tech_meta.aperture = props['exif:FNumber']
         image_tech_meta.focal_length = props['exif:FocalLength']
         image_tech_meta.exif_version = props['xmp:ExifVersion']
      end

      image_tech_meta.save!

      return image_tech_meta
   end
end
