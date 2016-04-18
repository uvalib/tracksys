class IngestSolrDoc < BaseJob

   require 'fedora'
   require 'hydra'
   require 'nokogiri'

   def set_originator(message)
      obj = message[:object]
      @status.update_attributes( :originator_type=>obj.class.to_s, :originator_id=>obj.id)
   end

   def iterate_children( component, solr_connection )
      component.children.each do |c|
         puts "INGEST SOLR: #{c.title}"
         do_ingest(c.pid, c, solr_connection)
         if c.has_children?
            iterate_children( c, solr_connection )
         end
      end
   end

   def do_ingest(pid, object, solr_connection)
      xml = Hydra.solr(object)
      begin
         solr_connection.add(Hydra.read_solr_xml(xml))
      rescue Errno::ECONNREFUSED
         on_failure("Add XML to solr failed; Connection to Solr #{STAGING_SOLR_URL} was refused")
      end
      Fedora.add_or_update_datastream(xml, pid, 'solrArchive', 'Index Data for Posting to Solr', :controlGroup => 'M')
   end

   def do_workflow(message)

      raise "Parameter 'object' is required" if message[:object].nil?
      @object = message[:object]
      @pid = @object.pid

      if ! @object.exists_in_repo?
         logger().error "ERROR: Object #{@pid} not found in #{FEDORA_REST_URL}"
         Fedora.create_or_update_object(@object, @object.title.to_s)
      end

      cascade = !message[:cascade].nil?
      cascade = false if cascade && @object.class.to_s != "Component"

      # Open Solr Connection
      @solr_connection = Solr::Connection.new("#{STAGING_SOLR_URL}", :autocommit => :off)

      if cascade
         iterate_children(@object, @solr_connection)
         return
      end

      do_ingest(@pid, @object, @solr_connection)

      on_success "The solrArchive datastream has been created for #{@pid} - #{@object.class.to_s} #{@object.id} and posted to #{STAGING_SOLR_URL}."
   end
end
