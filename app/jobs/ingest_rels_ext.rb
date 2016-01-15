class IngestRelsExt < BaseJob

  require 'fedora'
  require 'hydra'

  def perform(message)
    Job_Log.debug "IngestRelsExtProcessor received: #{message.to_json}"

    # Validate incoming message
    raise "Parameter 'type' is reqiured" if message[:type].blank?
    raise "Parameter 'type' must equal either 'ingest' or 'update'" unless message[:type].match('ingest') or message[:type].match('update')
    raise "Parameter 'object_class' is required" if message[:object_class].blank?
    raise "Parameter 'object_id' is required" if message[:object_id].blank?

    @type = message[:type]
    @object_class = message[:object_class]
    @object_id = message[:object_id]
    @object = @object_class.classify.constantize.find(@object_id)
    @messagable_id = message[:object_id]
    @messagable_type = message[:object_class]
    set_workflow_type()
    @pid = @object.pid
    instance_variable_set("@#{@object.class.to_s.underscore}_id", @object_id)

    if ! @object.exists_in_repo?
      Job_Log.error "ERROR: Object #{@pid} not found in #{FEDORA_REST_URL}"
      Fedora.create_or_update_object(@object, @object.title.to_s)
    end

    if @object.rels_ext
      Fedora.add_or_update_datastream(@object.rels_ext, @pid, 'RELS-EXT', 'Object Relationships', :controlGroup => 'M')
    else
      xml = Hydra.rels_ext(@object)
      Fedora.add_or_update_datastream(xml, @pid, 'RELS-EXT', 'Object Relationships', :controlGroup => 'M')
    end

    # Since the creation of a solr <doc> now requires both the rels-ext and descMetadata of an object, we must create both before a message is sent to ingest_solr_doc
    IngestSolrDoc.exec_now({ :type => @type, :object_class => @object_class, :object_id => @object_id })
    on_success "The RELS-EXT datastream has been created for #{@pid} - #{@object_class} #{@object_id}."
  end
end
