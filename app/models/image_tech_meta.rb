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
