class PublishToAS < BaseJob

   def do_workflow(message)
      raise "Parameter 'metadata' is required" if message[:metadata].blank?
      metadata = message[:metadata]
      if metadata.type != "ExternalMetadata" || metadata.external_system.name != "ArchivesSpace" 
         on_error("This item is not intended for publication to ArchivesSpace")
      end

      logger.info "Getting item details from ArchivesSpace #{metadata.external_uri}..."
      auth = ArchivesSpace.get_auth_session()
      obj  = ArchivesSpace.get_details(auth, metadata.external_uri, logger )
      if obj.nil?
         on_error("Unable to get ArchivesSpace resource from #{metadata.external_uri}")
      end

      dobj = ArchivesSpace.get_digital_object(auth, obj, metadata.pid)
      if dobj.nil?
         logger.info "Creating digital object..."
         ArchivesSpace.create_digital_object(auth, obj, metadata)
         logger.info "...success"
      else
         logger.info "ArchivesSpace already has a digital object for this item; nothing more to do."
      end
   end
end
