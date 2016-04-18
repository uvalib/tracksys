class IngestMarc < BaseJob

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

      xml = nil
      marcLocation = Hydra.marc(@object)
      if ! @object.exists_in_repo?
         logger().error "ERROR: Object #{@pid} not found in #{FEDORA_REST_URL}"
         Fedora.create_or_update_object(@object, @object.title.to_s)
      end

      Fedora.add_or_update_datastream(xml, @pid, 'MARC', 'Canonical MARC descriptive metadata from Blacklight', :dsLocation => marcLocation, :controlGroup => 'E')

      on_success "The MARC datastream has been created for #{@pid} - #{@object.class.to_s} #{@object.id}."
   end
end
