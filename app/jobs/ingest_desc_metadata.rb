class IngestDescMetadata < BaseJob

  require 'fedora'
  require 'hydra'

  def do_workflow(message)

    raise "Parameter 'object' is required" if message[:object].nil?
    object = message[:object]
    pid = object.pid

    if ! object.exists_in_repo?
      logger().error "ERROR: Object #{pid} not found in #{FEDORA_REST_URL}"
      Fedora.create_or_update_object(object, object.title.to_s)
    end

    # If an object already has a handcrafted desc_metadata value, this will be used to populate the descMetadata datastream.
    if not object.desc_metadata.blank?
      Fedora.add_or_update_datastream(object.desc_metadata, pid, 'descMetadata', 'MODS descriptive metadata', :controlGroup => 'M')
    else
      xml = Hydra.desc(object)
      Fedora.add_or_update_datastream(xml, pid, 'descMetadata', 'MODS descriptive metadata', :controlGroup => 'M')
    end

    msg = { :object=> object }
    IngestDcMetadata.exec_now( msg, self )

    # Since the creation of a solr <doc> now requires both the rels-ext and descMetadata of an object,
    # we must create both before a message is sent to ingest_solr_doc
    IngestRelsExt.exec_now( msg, self )
    on_success "The descMetadata datastream has been created for #{pid} - #{object.class.to_s} #{object.id}."
  end
end
