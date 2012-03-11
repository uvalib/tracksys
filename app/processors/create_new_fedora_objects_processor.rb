class CreateNewFedoraObjectsProcessor < ApplicationProcessor

  subscribes_to :create_new_fedora_objects, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :create_dl_deliverables
  publishes_to :ingest_desc_metadata
  publishes_to :ingest_marc
#  publishes_to :ingest_rels_ext
  publishes_to :ingest_rels_int
  publishes_to :ingest_rights_metadata
  publishes_to :ingest_tech_metadata
  publishes_to :ingest_transcription
#  publishes_to :ingest_solr_doc
  
  require 'fedora'
  require 'pidable'
 
  def on_message(message)  
    logger.debug "CreateNewFedoraObjectsProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Validate incoming message
    raise "Parameter 'source' is required" if hash[:source].blank?
    raise "Parameter 'object_class' is required" if hash[:object_class].blank?
    raise "Parameter 'object_id' is required" if hash[:object_id].blank?
    raise "Parameter 'last' is required" if hash[:last].blank?

    @source = hash[:source]
    @object_class = hash[:object_class]
    @object_id = hash[:object_id]
    @last = hash[:last]
    @object = @object_class.classify.constantize.find(@object_id)
    @messagable = @object
    
    @pid = @object.pid
    instance_variable_set("@#{@object.class.to_s.underscore}_id", @object_id)

    # Set up REST client
    @resource = RestClient::Resource.new FEDORA_REST_URL, :user => Fedora_username, :password => Fedora_password

    # Conditional logic to determine the object label in Fedora
    if @object.is_a? Bibl
      label = @object.title
    elsif @object.is_a? MasterFile
      label = @object.name_num
    elsif @object.is_a? Component
      label = @object.label
    elsif @object.is_a? EadRef
      label = @object.content_desc
    else
      on_error "Object is of an unknown class.  Please check code."
    end

    # Test to see whether an object already exist in the repo. This should force the user to use the UpdateFedoraObjectsProcessor rather than creating a new one.
    # More importantly, this will prevent the needless ingestion of Bibliographic objects each time a unit ingested that is part of that Bibl record.
#    if @object.exists_in_repo?
#      if @object.is_a? Bibl
#        on_success "The Bibl record for #{@object.pid} already exists and will not be recreated."
#      else
#        on_failure "Object #{@object.class.to_s} #{@object_id} already exists in #{FEDORA_REST_URL}."
#      end
#    else
      Fedora.create_or_update_object(@object, label)

      # This processor emits two kinds of messages:
      # 1.  Bound for creating text or XML-based datastreams
      # 2.  Bound for creating JP2 image

      default_message = ActiveSupport::JSON.encode({ :object_class => @object_class, :object_id => @object_id, :type => 'ingest' })

      # All objects get desc_metadata, rights_metadata
      publish :ingest_desc_metadata, default_message
      publish :ingest_rights_metadata, default_message
#      publish :ingest_rels_ext, default_message
      publish :ingest_rels_int, default_message
#      publish :ingest_solr_doc, default_message

      if @object.is_a? Bibl
        if @object.catalog_id
          publish :ingest_marc, default_message
        end
        
        if File.exist?(File.join(TEI_ARCHIVE_DIR, "#{@object.id}.tei.xml"))
          if not @object.content_model
            on_error "The Bibl record #{@object.id} has no content model set."
          end
          publish :ingest_tei_doc, default_message
        end
      end

      # MasterFiles (i.e. images)
      if @object.is_a? MasterFile
        @file_path = File.join(@source, @object.filename)
        image_creation_message = ActiveSupport::JSON.encode({ :mode => 'dl', :source => @file_path, :object_class => @object_class, :object_id => @object_id, :last => @last, :type => 'ingest' })

        publish :create_dl_deliverables, image_creation_message
        publish :ingest_tech_metadata, default_message

        # Only MasterFiles with transcritpion need have 
        if @object.transcription_text
          publish :ingest_transcription, default_message
        end
      end
      on_success "An object created for #{@pid}"
    #end
  end
end
