class BulkTransformXml < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"StaffMember", :originator_id=>message[:user].id )
   end

   def do_workflow(message)
      raise "Parameter 'user' is required" if message[:user].blank?
      raise "Parameter 'xsl_file' is required" if message[:xsl_file].blank?
      raise "Parameter 'mode' is required" if message[:mode].blank?

      unit = nil
      modes = [:global, :unit]
      user = message[:user]
      xsl_file = message[:xsl_file]
      mode = message[:mode]
      if !modes.include? mode
         on_error("Unsupported transform mode #{mode.to_s}")
      end

      if mode == :unit 
         unit = message[:unit]
         if unit.nil?
            on_error("Unit is required")
         end
         logger.info "Transforming all XML files in unit #{unit.id} with #{xsl_file}"
      else
         logger.info "Transforming *ALL* XML files with #{xsl_file}"
      end

      if !File.exist? xsl_file 
         on_error("XSL File #{xsl_file} not found")
      end

      on_error("NOT IMPLEMENTED")
   end
end
