class PublishToAS < BaseJob

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      unit = message[:unit]

      # Once sanity check. Make sure the unit is really supposed to go to AS before oing anything.
      if unit.metadata.type != "ExternalMetadata" || unit.metadata.external_system != "ArchivesSpace" || unit.throw_away == true
         logger.warn("This unit is not intended to publication to ArchivesSpace. Skipping.")
         return
      end

      auth = ArchivesSpace.get_auth_session()
      bits = unit.metadata.external_uri.split("/")
      obj = nil
      if bits[3] == "resources"
         logger.info "Look up ArchivesSpace object: #{unit.metadata.external_uri}"
         obj = ArchivesSpace.get_resource(auth, bits[2], bits[4])
      elsif bits[3] == "archival_objects"
         logger.info "Look up ArchivesSpace object: #{unit.metadata.external_uri}"
         obj = ArchivesSpace.get_archival_object(auth, bits[2], bits[4])
      else
         logger.info "External URI has unsupported parent type in URI: #{bits[3]}"
      end

      if !obj.nil?
         if ArchivesSpace.has_digital_object?(auth, obj, unit.metadata.pid) == false
            begin
               logger.info "Creating digital object..."
               ArchiveSpace.create_digital_object(auth, obj, unit.metadata, true)
               logger.info "...success"
            rescue Exception=>e
               logger.error "Unable to create ArchivesSpace digital object: #{e.message}"
            end
         else
            logger.info "ArchivesSpace already has a digital object for this item; nothing more to do."
         end
      end
   end
end
