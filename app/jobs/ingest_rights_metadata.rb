class IngestRightsMetadata < BaseJob

  require 'fedora'
  require 'hydra'

  def perform(message)
    Job_Log.debug "IngestRightsMetadataProcessor received: #{message.to_json}"

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

    # The POLICY datastream should only be posted if the access policy is anything but permit to all.  So exclude this processor's
    # work if @object.availability_policy_id == 1
    if not @object.availability_policy_id == 1
      # Since POLICY is an externally referenced datastream, the xml passed to add_or_update_datastream is empty.
      xml = nil
      dsLocation = Hydra.access(@object)

      # To conform to potentially legacy Fedora requirements, we will create a POLICY datastream.
      Fedora.add_or_update_datastream(xml, @pid, 'POLICY', 'Fedora-required policy datastream', :dsLocation => dsLocation, :controlGroup => 'R')
      on_success "The POLICY datastream has been created for #{@pid} - #{@object_class} #{@object_id}."
    else
      on_success "The POLICY datastream was not created because this object is set to Public."
    end
  end
end
