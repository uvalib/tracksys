require "#{Hydraulics.models_dir}/image_tech_meta"

class ImageTechMeta
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

