class IngestRelsExt < BaseJob

   require 'fedora'
   require 'hydra'

   def set_originator(message)
      obj = message[:object]
      @status.update_attributes( :originator_type=>obj.class.to_s, :originator_id=>obj.id)
   end

   def do_workflow(message)
      raise "Parameter 'object' is required" if message[:object].nil?
      @object = message[:object]
      @pid = @object.pid
      if ! @object.exists_in_repo?
         logger().error "ERROR: Object #{@pid} not found in #{FEDORA_REST_URL}"
         Fedora.create_or_update_object(@object, @object.title.to_s)
      end

      if @object.rels_ext
         Fedora.add_or_update_datastream(@object.rels_ext, @pid, 'RELS-EXT', 'Object Relationships', :controlGroup => 'M')
      else
         xml = Hydra.rels_ext(@object)
         Fedora.add_or_update_datastream(xml, @pid, 'RELS-EXT', 'Object Relationships', :controlGroup => 'M')
      end

      #  # Since the creation of a solr <doc> now requires both the rels-ext and descMetadata of an object,
      #  # we must create both before a message is sent to ingest_solr_doc
      #  IngestSolrDoc.exec_now({ :object => @object }, self)
      # LFF Don't do the above because the ingest happens before data is avaialble resulting in bad solr index
      #
      on_success "The RELS-EXT datastream has been created for #{@pid} - #{@object.class.to_s} #{@object.id}."
   end
end
