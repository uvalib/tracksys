# ImageTechMeta represents image technical metadata. An ImageTechMeta record is
# an extension of a single MasterFile record and is applicable only for a
# MasterFile of type "image".
class ImageTechMeta < ApplicationRecord
   enum flip_axis: {not_flipped:0 , y_axis: 1, x_axis: 2}
   belongs_to :master_file

   validates :master_file_id, :presence => true
   validates :master_file_id, :uniqueness => true
   validates :resolution, :width, :height, :depth, :numericality => {:greater_than => 0, :allow_nil => true}
   validates :master_file, :presence => {
      :message => "association with this MasterFile is no longer valid because the MasterFile object no longer exists."
   }

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

   # Returns this record's +image_format+ value.
   def format
      return image_format
   end
end

# == Schema Information
#
# Table name: image_tech_meta
#
#  id             :integer          not null, primary key
#  master_file_id :integer          default(0), not null
#  image_format   :string(255)
#  width          :integer
#  height         :integer
#  resolution     :integer
#  color_space    :string(255)
#  depth          :integer
#  compression    :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  color_profile  :string(255)
#  equipment      :string(255)
#  software       :string(255)
#  model          :string(255)
#  exif_version   :string(255)
#  capture_date   :datetime
#  iso            :integer
#  exposure_bias  :string(255)
#  exposure_time  :string(255)
#  aperture       :string(255)
#  focal_length   :decimal(10, )
#
