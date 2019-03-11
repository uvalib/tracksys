module TechMetadata
   # Create image tech metadata
   def self.create(master_file, image_path)
      image = MiniMagick::Image.open(image_path)

      image_tech_meta = ImageTechMeta.new
      image_tech_meta.master_file = master_file
      image_tech_meta.image_format = image.type

      if image["%[colorspace]"] == 'RGBColorspace' ||  image["%[colorspace]"] == "sRGB"
         image_tech_meta.color_space = 'RGB'
         image_tech_meta.depth = image["%[depth]"] * 3
      end

      if image["%[compression]"].blank? || image["%[compression]"] == 'None'
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

      image_tech_meta.width = image.width
      image_tech_meta.height = image.height
      image_tech_meta.resolution = image.resolution.first
      image_tech_meta.equipment = image["%[tiff:make]"] 
      image_tech_meta.software = image["%[tiff:software]"]
      image_tech_meta.model = image["%[tiff:model]"]
      exif_date = image["%[exif:DateTimeOriginal]"]
      if !exif_date.blank?
         image_tech_meta.capture_date = exif_date.split(":",3).join("/").to_datetime
      end
      image_tech_meta.iso = image["%[exif:ISOSpeedRatings]"] 
      image_tech_meta.exposure_bias = image["%exif:ExposureBiasValue]"]
      image_tech_meta.exposure_time = image["%exif:ExposureTime]"]
      image_tech_meta.aperture = image["%exif:FNumber]"]
      image_tech_meta.focal_length = image["%exif:FocalLength]"]
      image_tech_meta.exif_version = image["%xmp:ExifVersion]"]

      image_tech_meta.save!

      return image_tech_meta
   end
end
