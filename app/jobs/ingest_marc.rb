class IngestMarc < BaseJob

  require 'fedora'
  require 'hydra'

  def perform(message)
    Job_Log.debug "IngestMarcProcessor received: #{message.to_json}"

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

    xml = nil
    marcLocation = Hydra.marc(@object)
    if ! @object.exists_in_repo?
      Job_Log.error "ERROR: Object #{@pid} not found in #{FEDORA_REST_URL}"
      Fedora.create_or_update_object(@object, @object.title.to_s)
    end

    Fedora.add_or_update_datastream(xml, @pid, 'MARC', 'Canonical MARC descriptive metadata from Blacklight', :dsLocation => marcLocation, :controlGroup => 'E')

    on_success "The MARC datastream has been created for #{@pid} - #{@object_class} #{@object_id}."
  end
end
