class IngestTranscription < BaseJob

   require 'fedora'
   require 'hydra'

   def set_originator(message)
      @status.update_attributes( :originator_type=>message[:object_class], :originator_id=>message[:object_id])
   end

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'type' is reqiured" if message[:type].blank?
      raise "Parameter 'type' must equal either 'ingest' or 'update'" unless message[:type].match('ingest') or message[:type].match('update')
      raise "Parameter 'object_class' is required" if message[:object_class].blank?
      raise "Parameter 'object_id' is required" if message[:object_id].blank?

      @type = message[:type]
      @object_class = message[:object_class]
      @object_id = message[:object_id]
      @object = @object_class.classify.constantize.find(@object_id)
      @pid = @object.pid

      if ! @object.exists_in_repo?
         logger().error "ERROR: Object #{@pid} not found in #{FEDORA_REST_URL}"
         Fedora.create_or_update_object(@object, @object.title.to_s)
      end

      xml = @object.transcription_text
      Fedora.add_or_update_datastream(xml, @pid, 'transcription', 'Transcription', :contentType => 'text/plain', :mimeType => 'text/plain', :controlGroup => 'M')

      on_success "The transcription datastream has been created for #{@pid} - #{@object_class} #{@object_id}."
   end
end
