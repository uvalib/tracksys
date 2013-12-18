class IngestDcMetadataProcessor < ApplicationProcessor

  require 'fedora'
  require 'hydra'

  subscribes_to :ingest_dc_metadata, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)  
    logger.debug "IngestDcMetadataProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Validate incoming message
    raise "Parameter 'type' is reqiured" if hash[:type].blank?
    raise "Parameter 'type' must equal either 'ingest' or 'update'" unless hash[:type].match('ingest') or hash[:type].match('update')
    raise "Parameter 'object_class' is required" if hash[:object_class].blank?
    raise "Parameter 'object_id' is required" if hash[:object_id].blank?

    @type = hash[:type]
    @object_class = hash[:object_class]
    @object_id = hash[:object_id]
    @object = @object_class.classify.constantize.find(@object_id)
    @messagable_id = hash[:object_id]
    @messagable_type = hash[:object_class]
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)

    @pid = @object.pid
    instance_variable_set("@#{@object.class.to_s.underscore}_id", @object_id)      

    if ! @object.exists_in_repo?
      logger.error "ERROR: Object #{@pid} not found in #{FEDORA_REST_URL}"
      Fedora.create_or_update_object(@object, @object.title.to_s)
    end

    if @object.dc
      Fedora.add_or_update_datastream(@object.dc, @pid, 'DC', 'Dublin Core Record')
    else
      xml = Hydra.dc(@object)
      Fedora.add_or_update_datastream(xml, @pid, 'DC', 'Dublin Core Record')
    end
    on_success "The DC datastream has been created for #{@pid} - #{@object_class} #{@object_id}."
  end
end
