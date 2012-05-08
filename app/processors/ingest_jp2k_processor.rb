class IngestJp2kProcessor < ApplicationProcessor

  require 'fedora'
  require 'hydra'

  subscribes_to :ingest_jp2k, {:ack=>'client', 'activemq.prefetchSize' => 1}
#  publishes_to :update_rels_ext_with_indexer_content_model
  publishes_to :delete_unit_copy_for_deliverable_generation
  publishes_to :update_unit_date_dl_deliverables_ready  

  def on_message(message)  
    logger.debug "Ingest JP2K Processor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'last' is required" if hash[:last].blank?
    raise "Parameter 'source' is required" if hash[:source].blank?
    raise "Parameter 'object_class' is required" if hash[:object_class].blank?
    raise "Parameter 'object_id' is required" if hash[:object_id].blank?
    raise "Parameter 'jp2k_path' is required" if hash[:jp2k_path].blank?

    @object_class = hash[:object_class]
    @object_id = hash[:object_id]
    @object = @object_class.classify.constantize.find(@object_id)
    @messagable_id = hash[:object_id]
    @messagable_type = hash[:object_class]
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)
    @jp2k_path = hash[:jp2k_path]
    @source = hash[:source]

    @pid = @object.pid
    instance_variable_set("@#{@object.class.to_s.underscore}_id", @object_id)
        
    # Read jp2 file from disk
    file = File.read(@jp2k_path)
    
    Fedora.add_or_update_datastream(file, @pid, 'content', 'JPEG-2000 Binary', :controlGroup => 'M', :versionable => "false", :mimeType => "image/jp2")
    
    # Delete jp2 file from disk
    File.delete(@jp2k_path)

    on_success "The content datastream (JP2K) has been created for #{@pid} - #{@object_class} #{@object_id}."

    if hash[:last] == 1
      # Delete the instance variable so the following success and error messages only get posted to the Unit and not the MasterFile
      instance_variable_set("@#{@object.class.to_s.underscore}_id", nil)
      
      @unit_id = @object.unit.id     
      message = ActiveSupport::JSON.encode({ :unit_id => @unit_id })
#      publish :update_rels_ext_with_indexer_content_model, message
      publish :update_unit_date_dl_deliverables_ready, message
      on_success "Last JP2K for Unit #{@unit_id} created."

      if @source.match("#{FINALIZATION_DIR_MIGRATION}") or @source.match("#{FINALIZATION_DIR_PRODUCTION}")
        message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :mode => 'dl'})
        publish :delete_unit_copy_for_deliverable_generation, message
      end
    end
  end
end
