class CreateNewFedoraObjects < BaseJob

   require 'fedora'
   require 'pidable'

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'source' is required" if message[:source].blank?
      raise "Parameter 'object' is required" if message[:object].blank?
      raise "Parameter 'last' is required" if message[:last].blank?

      source = message[:source]
      object = message[:object]
      last = message[:last]

      # Conditional logic to determine the object label in Fedora
      if object.is_a? Bibl
         label = object.title
      elsif object.is_a? MasterFile
         label = object.title
      elsif object.is_a? Component
         label = object.label
      else
         on_error "Object is of an unknown class.  Please check code."
      end

      # Create an object in fedora if it doesn't exist. Update if it does
      Fedora.create_or_update_object(object, label)

      # All ingestable objects have a date_dl_ingest attribute which can be updated at this time.
      object.update_attribute(:date_dl_ingest, Time.now)

      # This processor emits two kinds of messages:
      # 1.  Bound for creating text or XML-based datastreams
      # 2.  Bound for creating JP2 image

      # All objects get desc_metadata, rights_metadata
      default_message = { :object=> object}
      IngestDescMetadata.exec_now(default_message, self)

      if object.is_a? Bibl
         if object.catalog_key
            IngestMarc.exec_now( default_message, self )
         end
      end

      # MasterFiles (i.e. images)
      if object.is_a? MasterFile
         file_path = File.join(source, object.filename)
         CreateDlDeliverables.exec_now({ :source => file_path, :master_file=> object, :last => last }, self)
         IngestTechMetadata.exec_now( default_message, self )

         # Only MasterFiles with transcritpion need have
         if object.transcription_text
            IngestTranscription.exec_now( default_message, self )
         end
      end
      on_success "An object created for #{object.pid}"
   end
end
