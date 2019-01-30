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
      if !File.exist? xsl_file 
         on_error("XSL File #{xsl_file} not found")
      end

      if mode == :unit 
         unit = message[:unit]
         if unit.nil?
            on_error("Unit is required")
         end
         logger.info "Transforming all XML files in unit #{unit.id} with #{xsl_file}"
         transform_unit(user, xsl_file, unit)
      else
         logger.info "Transforming *ALL* XML files with #{xsl_file}"
         transform_all(user, xsl_file)
      end
   end

   def transform_unit(user, xsl_file, unit) 
      xsl_uuid = File.basename(xsl_file, ".xsl")
      logger.info "The UUID for this transform is #{xsl_uuid}"
      unit.master_files.each do |mf|
         next if unit.metadata.id == mf.metadata.id 
         next if mf.metadata.type != "XmlMetadata"
         if Settings.use_saxon_servlet == "true"
            new_xml = servlet_transform(mf.metadata, xsl_uuid)
         else
            new_xml = local_transform(mf.metadata, xsl_file)
         end
         if !new_xml.blank? && new_xml != mf.metadata.desc_metadata 
            MetadataVersion.create(metadata: mf.metadata, staff_member: user, desc_metadata:  mf.metadata.desc_metadata, version_tag: xsl_uuid)
            mf.metadata.update(desc_metadata: new_xml)
         end
      end
   end

   def transform_all(user, xsl_file) 
      xsl_uuid = File.basename(xsl_file, ".xsl")
      logger.info "The UUID for this transform is #{xsl_uuid}"
      XmlMetadata.all.for_each do |md| 
         if Settings.use_saxon_servlet == "true"
            new_xml = servlet_transform(md, xsl_uuid)
         else
            new_xml = local_transform(md, xsl_file)
         end
         if !new_xml.blank? && new_xml != md.desc_metadata 
            MetadataVersion.create(metadata: md, staff_member: user, desc_metadata:  md.desc_metadata, version_tag: xsl_uuid)
            md.update(desc_metadata: new_xml)
         end
      end
   end

   def servlet_transform(metadata, xsl_uuid)
      payload = {}
      payload['source'] = "#{Settings.tracksys_url}/api/metadata/#{metadata.pid}?type=desc_metadata"
      payload['style'] = "#{Settings.tracksys_url}/api/stylesheet/user?uuid=#{xsl_uuid}"
      uri = "http://#{Settings.saxon_url}:#{Settings.saxon_port}/saxon/SaxonServlet"
      response = RestClient.post(uri, payload)
      if response.code == 200 
         return response.body
      else 
         return ""
      end
   end

   def local_transform(metadata, xsl_file)
      saxon = "java -jar #{File.join(Rails.root, "lib", "Saxon-HE-9.7.0-8.jar")}"

      tmp = Tempfile.new([metadata.pid, ".xml"])
      tmp.write(metadata.desc_metadata)
      tmp.close

      cmd = "#{saxon} -s:#{tmp.path} -xsl:#{xsl_file}"
      return `#{cmd}`
   end
end
