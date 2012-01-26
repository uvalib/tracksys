class IngestTechMetadataProcessor < ApplicationProcessor

  require 'fedora'
  require 'hydra'

  subscribes_to :ingest_tech_metadata, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)  
    logger.debug "IngestTechMetadataProcessor received: " + message
    
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

    @pid = @object.pid
    instance_variable_set("@#{@object.class.to_s.underscore}_id", @object_id)
        
    xml = Hydra.tech(@object)
    Fedora.add_or_update_datastream(xml, @pid, 'technicalMetadata', 'Technical metadata', :controlGroup => 'M')

    on_success "The technicalMetadata datastream has been created for #{@pid} - #{@object_class} #{@object_id}."
  end
end
