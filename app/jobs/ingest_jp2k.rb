class IngestJp2k < BaseJob

   require 'fedora'
   require 'hydra'

   def do_workflow(message)

      raise "Parameter 'master_file' is required" if message[:master_file].blank?
      raise "Parameter 'jp2k_path' is required" if message[:jp2k_path].blank?

      master_file = message[:master_file]
      jp2k_path = message[:jp2k_path]
      pid = master_file.pid

      # Read jp2 file from disk
      file = File.read(jp2k_path)

      if ! master_file.exists_in_repo?
         logger().error "ERROR: Object #{pid} not found in #{FEDORA_REST_URL}"
         Fedora.create_or_update_object(master_file, master_file.title.to_s)
      end
      Fedora.add_or_update_datastream(file, pid, 'content', 'JPEG-2000 Binary', :controlGroup => 'M', :versionable => "false", :mimeType => "image/jp2")

      # Delete jp2 file from disk
      File.delete(jp2k_path)

      on_success "The content datastream (JP2K) has been created for #{pid} - MasterFile #{master_file.id}."
   end
end
