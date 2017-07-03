class CreateImageTechnicalMetadata < BaseJob

   require 'exifr'
   require 'rmagick'

   def do_workflow(message)
      raise "Parameter 'master_file' is required" if message[:master_file].blank?
      raise "Parameter 'source' is required" if message[:source].blank?
      image_path = message[:source]
      master_file = message[:master_file]
      TechMetadata.create(master_file, image_path)
end
