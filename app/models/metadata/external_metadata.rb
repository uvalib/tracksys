class ExternalMetadata < Metadata
   #------------------------------------------------------------------
   # Prevent setting data valid for other classes in the STI model
   validates :catalog_key, presence: false
   validates :barcode, presence: false
   validates :call_number, presence: false
   validates :desc_metadata, presence: false
   validates :external_system, presence: true
   validates :external_uri, presence: true

   before_save do
      # external metadata can not be published from tracksys
      self.discoverability = false
      self.availability_policy = nil
   end

   def url_fragment
      return "external_metadata"
   end
end
