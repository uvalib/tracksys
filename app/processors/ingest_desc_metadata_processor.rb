class IngestDescMetadataProcessor < ApplicationProcessor

  require 'fedora'
  require 'hydra'

  subscribes_to :ingest_desc_metadata, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :ingest_dc_metadata
  publishes_to :ingest_rels_ext
  
  def on_message(message)  
    logger.debug "IngestDescMetadataProcessor received: " + message
    
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
        
    # If an object already has a handcrafted desc_metadata value, this will be used to populate the descMetadata datastream.
    if @object.desc_metadata
      Fedora.add_or_update_datastream(@object.desc_metadata, @pid, 'descMetadata', 'MODS descriptive metadata', :controlGroup => 'M')
    else
      xml = Hydra.desc(@object)
      Fedora.add_or_update_datastream(xml, @pid, 'descMetadata', 'MODS descriptive metadata', :controlGroup => 'M') 
    end

    message = ActiveSupport::JSON.encode({ :type => @type, :object_class => @object_class, :object_id => @object_id })
    publish :ingest_dc_metadata, message
    
    # Since the creation of a solr <doc> now requires both the rels-ext and descMetadata of an object, we must create both before a message is sent to ingest_solr_doc
    publish :ingest_rels_ext, message
    on_success "The descMetadata datastream has been created for #{@pid} - #{@object_class} #{@object_id}."
  end
end
