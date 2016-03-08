class IngestSolrDoc < BaseJob

  require 'fedora'
  require 'hydra'
  require 'nokogiri'

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

    # Open Solr Connection
    @solr_connection = Solr::Connection.new("#{STAGING_SOLR_URL}", :autocommit => :off)

    if ! @object.exists_in_repo?
      logger().error "ERROR: Object #{@pid} not found in #{FEDORA_REST_URL}"
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
      begin
         @solr_connection.add(Hydra.read_solr_xml(xml))
      rescue Errno::ECONNREFUSED
         on_failure("Add XML to solr failed; Connection to Solr #{STAGING_SOLR_URL} was refused")
      end
      Fedora.add_or_update_datastream(xml, @pid, 'solrArchive', 'Index Data for Posting to Solr', :controlGroup => 'M')
    else
      xml = Hydra.solr(@object)
      begin
         @solr_connection.add(Hydra.read_solr_xml(xml))
      rescue Errno::ECONNREFUSED
         on_failure("Add XML to solr failed; Connection to Solr #{STAGING_SOLR_URL} was refused")
      end
      Fedora.add_or_update_datastream(xml, @pid, 'solrArchive', 'Index Data for Posting to Solr', :controlGroup => 'M')
    end

    on_success "The solrArchive datastream has been created for #{@pid} - #{@object_class} #{@object_id} and posted to #{STAGING_SOLR_URL}."
  end
end
