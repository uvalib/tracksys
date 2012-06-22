class IngestRelsIntProcessor < ApplicationProcessor

  # We are going to stop creating RELS-INT for the time being since the indexable CModel is not currently
  # enforced and won't be for a while.  If it is, it will have a new name and Mike Durbin will tell me.x

  require 'fedora'
  require 'hydra'

  subscribes_to :ingest_rels_int, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)  
    logger.debug "IngestRelsIntProcessor received: " + message
    
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
        
    if @object.rels_int
      Fedora.add_or_update_datastream(@object.rels_int, @pid, 'RELS-INT', 'Datastream Relationships', :controlGroup => 'M')
    else
      xml = Hydra.rels_int(@object)
      Fedora.add_or_update_datastream(xml, @pid, 'RELS-INT', 'Datastream Relationships', :controlGroup => 'M')
    end
    on_success "The RELS-INT datastream has been created for #{@pid} - #{@object_class} #{@object_id}."
  end
end
