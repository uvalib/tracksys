class IngestTeiDoc < BaseJob

  require 'fedora'
  require 'hydra'

  def perform(message)
    Job_Log.debug "IngestTeiDocProcessor received: #{message.to_json}"

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

    xml = File.read(File.join(TEI_ARCHIVE_DIR, "#{@object_id}.tei.xml"))
    Fedora.add_or_update_datastream(xml, @pid, 'TEI', 'TEI Transcription Document', :contentType => 'text/xml', :mimeType => 'text/xml', :controlGroup => 'M')

    dsLocation = Hydra.tei(@object)
    Fedora.add_or_update_datastream(xml, @pid, 'XTF', 'XTF View of TEI Datastream Content', :dsLocation => dsLocation, :controlGroup => 'E')

    FileUtils.cp File.join(TEI_ARCHIVE_DIR, "#{@object_id}.tei.xml"), File.join(XTF_DELIVERY_DIR, "#{@object.content_model.name}/#{@object_id}.tei.xml")

    on_success "The TEI datastream has been created for #{@pid} - #{@object_class} #{@object_id}."
  end
end
