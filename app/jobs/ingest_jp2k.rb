class IngestJp2k < BaseJob

  require 'fedora'
  require 'hydra'

  def set_originator(message)
     obj = message[:object]
     @status.update_attributes( :originator_type=>obj.class.to_s, :originator_id=>obj.id)
  end

  def do_workflow(message)

    raise "Parameter 'last' is required" if message[:last].blank?
    raise "Parameter 'source' is required" if message[:source].blank?
    raise "Parameter 'object' is required" if message[:object].blank?
    raise "Parameter 'jp2k_path' is required" if message[:jp2k_path].blank?

    @object = message[:object]
    @jp2k_path = message[:jp2k_path]
    @source = message[:source]
    @pid = @object.pid

    # Read jp2 file from disk
    file = File.read(@jp2k_path)

    if ! @object.exists_in_repo?
      logger().error "ERROR: Object #{@pid} not found in #{FEDORA_REST_URL}"
      Fedora.create_or_update_object(@object, @object.title.to_s)
    end
    Fedora.add_or_update_datastream(file, @pid, 'content', 'JPEG-2000 Binary', :controlGroup => 'M', :versionable => "false", :mimeType => "image/jp2")

    # Delete jp2 file from disk
    File.delete(@jp2k_path)

    on_success "The content datastream (JP2K) has been created for #{@pid} - #{@object.class.to_s} #{@object.id}."

    if message[:last] == 1

      @unit_id = @object.unit.id
      UpdateUnitDateDlDeliverablesReady.exec_now({ :unit_id => @unit_id }, self)

      on_success "Last JP2K for Unit #{@unit_id} created."

      if @source.match("#{FINALIZATION_DIR_MIGRATION}") or @source.match("#{FINALIZATION_DIR_PRODUCTION}")
        DeleteUnitCopyForDeliverableGeneration.exec_now({ :unit_id => @unit_id, :mode => 'dl'}, self)
      end
    end
  end
end
