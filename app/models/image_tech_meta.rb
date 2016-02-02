# ImageTechMeta represents image technical metadata. An ImageTechMeta record is
# an extension of a single MasterFile record and is applicable only for a
# MasterFile of type "image".
class ImageTechMeta < ActiveRecord::Base

   # include HasFormat

   # COLOR_SPACES = %w[RGB GRAY CMYK]  # These are the values used in iView XML files (which are imported to create MasterFile and ImageTechMeta records)

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :master_file

   #------------------------------------------------------------------
   # validation
   #------------------------------------------------------------------
   validates :master_file_id, :presence => true
   validates :master_file_id, :uniqueness => true
   validates :resolution, :width, :height, :depth, :numericality => {:greater_than => 0, :allow_nil => true}
   validates :master_file, :presence => {
      :message => "association with this MasterFile is no longer valid because the MasterFile object no longer exists."
   }

   #------------------------------------------------------------------
   # public class methods
   #------------------------------------------------------------------
   # These methods return a string containing a brief description for a specific
   # column, for which the usage or format is not inherently obvious.
   def ImageTechMeta.width_description
      return 'Image width/height in pixels.'
   end

   def ImageTechMeta.depth_description
      return 'Color depth in bits. Normally 1 for bitonal, 8 for grayscale, 24 for color.'
   end

   def ImageTechMeta.compression_description
      return 'Name of compression scheme, or "Uncompressed" for no compression.'
   end


   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------
   # Returns this record's +image_format+ value.
   def format
      return image_format
   end

   def mime_type
      if format.blank?
         return nil
      else
         # image formats
         if format.match(/^(gif|jpeg|tiff)$/i)
            return "image/#{format.downcase}"
         elsif format.match(/^mrsid$/i)
            return "image/x-mrsid"
         elsif format.match(/^jpeg ?2000$/i)
            return 'image/jp2'
            # text formats
         elsif format == 'TEI-XML'
            return 'text/xml'
            # audio formats
         elsif format == 'WAV'
            return 'audio/wav'
            # video formats
         elsif format == 'AVI'
            return 'video/avi'
         else
            return nil
         end
      end
   end
end
# == Schema Information
#
# Table name: image_tech_meta
#
#  id             :integer(4)      not null, primary key
#  master_file_id :integer(4)      default(0), not null
#  image_format   :string(255)
#  width          :integer(4)
#  height         :integer(4)
#  resolution     :integer(4)
#  color_space    :string(255)
#  depth          :integer(4)
#  compression    :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  color_profile  :string(255)
#  equipment      :string(255)
#  software       :string(255)
#  model          :string(255)
#  exif_version   :string(255)
#  capture_date   :datetime
#  iso            :integer(4)
#  exposure_bias  :string(255)
#  exposure_time  :string(255)
#  aperture       :string(255)
#  focal_length   :integer(10)
#
