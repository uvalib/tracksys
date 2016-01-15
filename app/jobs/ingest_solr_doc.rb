class IngestSolrDoc < BaseJob

  require 'fedora'
  require 'hydra'
  require 'nokogiri'

  def perform(message)
    Job_Log.debug "IngestSolrDocProcessor received: #{message.to_json}"

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

    # Open Solr Connection
    @solr_connection = Solr::Connection.new("#{STAGING_SOLR_URL}", :autocommit => :off)

    if ! @object.exists_in_repo?
      Job_Log.error "ERROR: Object #{@pid} not found in #{FEDORA_REST_URL}"
      Fedora.create_or_update_object(@object, @object.title.to_s)
    end

    # If an object already has a handcrafted desc_metadata value, this will be used to populate the descMetadata datastream.
    if @object.solr
      doc = Nokogiri::XML(@object.solr)
      nodes = doc.xpath("//field[@name='repository_address_display']")
      nodes[0].content = FEDORA_PROXY_URL
      @object.solr = doc.to_xml
      @object.save!
      xml = @object.solr
      @solr_connection.add(Hydra.read_solr_xml(xml))
      Fedora.add_or_update_datastream(xml, @pid, 'solrArchive', 'Index Data for Posting to Solr', :controlGroup => 'M')
    else
      xml = Hydra.solr(@object)
      @solr_connection.add(Hydra.read_solr_xml(xml))
      Fedora.add_or_update_datastream(xml, @pid, 'solrArchive', 'Index Data for Posting to Solr', :controlGroup => 'M')
    end

    on_success "The solrArchive datastream has been created for #{@pid} - #{@object_class} #{@object_id} and posted to #{STAGING_SOLR_URL}."
  end
end
