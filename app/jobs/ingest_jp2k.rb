class IngestJp2k < BaseJob

  require 'fedora'
  require 'hydra'

  def perform(message)
    Job_Log.debug "Ingest JP2K Processor received: #{message.to_json}"

    raise "Parameter 'last' is required" if message[:last].blank?
    raise "Parameter 'source' is required" if message[:source].blank?
    raise "Parameter 'object_class' is required" if message[:object_class].blank?
    raise "Parameter 'object_id' is required" if message[:object_id].blank?
    raise "Parameter 'jp2k_path' is required" if message[:jp2k_path].blank?

    @object_class = message[:object_class]
    @object_id = message[:object_id]
    @object = @object_class.classify.constantize.find(@object_id)
    @messagable_id = message[:object_id]
    @messagable_type = message[:object_class]
    set_workflow_type()
    @jp2k_path = message[:jp2k_path]
    @source = message[:source]

    @pid = @object.pid
    instance_variable_set("@#{@object.class.to_s.underscore}_id", @object_id)

    # Read jp2 file from disk
    file = File.read(@jp2k_path)

    if ! @object.exists_in_repo?
      Job_Log.error "ERROR: Object #{@pid} not found in #{FEDORA_REST_URL}"
      Fedora.create_or_update_object(@object, @object.title.to_s)
    end
    Fedora.add_or_update_datastream(file, @pid, 'content', 'JPEG-2000 Binary', :controlGroup => 'M', :versionable => "false", :mimeType => "image/jp2")

    # Delete jp2 file from disk
    File.delete(@jp2k_path)

    on_success "The content datastream (JP2K) has been created for #{@pid} - #{@object_class} #{@object_id}."

    if message[:last] == 1
      # Delete the instance variable so the following success and error messages only get posted to the Unit and not the MasterFile
      instance_variable_set("@#{@object.class.to_s.underscore}_id", nil)

      @unit_id = @object.unit.id
      UpdateUnitDateDlDeliverablesReady.exec_now({ :unit_id => @unit_id })

      on_success "Last JP2K for Unit #{@unit_id} created."

      if @source.match("#{FINALIZATION_DIR_MIGRATION}") or @source.match("#{FINALIZATION_DIR_PRODUCTION}")
        DeleteUnitCopyForDeliverableGeneration.exec_now({ :unit_id => @unit_id, :mode => 'dl'})
      end
    end
  end
end
