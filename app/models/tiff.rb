class Tiff < MasterFile
  def say_hello
    return "Hi! I am a #{self.type}"
  end

  def mime_type
    "image/tiff"
  end
end

