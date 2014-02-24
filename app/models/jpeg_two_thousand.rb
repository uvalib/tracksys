class JpegTwoThousand < MasterFile
  def say_hello
    return "Hi! I am a #{self.type}"
  end

  def mime_type
    "image/jp2"
  end
end
