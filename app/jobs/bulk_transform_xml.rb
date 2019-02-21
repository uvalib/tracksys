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
         fatal_error("Unsupported transform mode #{mode.to_s}")
      end
      if !File.exist? xsl_file
         fatal_error("XSL File #{xsl_file} not found")
      end

      if Settings.use_saxon_servlet == "true"
         logger.info "Transformations will be done with #{Settings.saxon_url}"
      else
         logger.info "Transformations will be done with a local version of saxon"
      end

      if mode == :unit
         unit = message[:unit]
         if unit.nil?
            fatal_error("Unit is required")
         end
         logger.info "Transforming all XML files in unit #{unit.id} with #{xsl_file}"
         transform_unit(user, xsl_file, unit, message[:comment])
      else
         logger.info "Transforming *ALL* XML files with #{xsl_file}"
         transform_all(user, xsl_file, message[:comment])
      end
   end

   def transform_unit(user, xsl_file, unit, comment)
      xsl_uuid = File.basename(xsl_file, ".xsl")
      logger.info "The UUID for this transform is #{xsl_uuid}"
      unit.master_files.each do |mf|
         next if mf.metadata.nil?
         next if mf.metadata.type != "XmlMetadata"
         next if mf.metadata.metadata_versions.where(version_tag: xsl_uuid).exists?

         logger.info "Transform XmlMetadata #{mf.metadata.id} : #{mf.metadata.pid}"
         if Settings.use_saxon_servlet == "true"
            new_xml = servlet_transform(mf.metadata, xsl_uuid)
         else
            new_xml = local_transform(mf.metadata, xsl_file)
         end
         if MetadataVersion.has_changes? new_xml, mf.metadata.desc_metadata
            logger.info "Transform successful; create new version"
            MetadataVersion.create(metadata: mf.metadata, staff_member: user, desc_metadata:  mf.metadata.desc_metadata,
               version_tag: xsl_uuid, comment: comment)
            mf.metadata.update(desc_metadata: new_xml)
         else
            logger.info "Transform not successful, or caused no changes"
         end
      end
   end

   def self.test_transform(metadata_id, xsl_file)
      xsl_uuid = File.basename(xsl_file, ".xsl")
      puts "Get metadata #{metadata_id}"
      md = XmlMetadata.find(metadata_id)
      puts "Servlet transform"
      new_xml = ""
      begin
         payload = {}
         payload['source'] = "#{Settings.tracksys_url}/api/metadata/#{md.pid}?type=desc_metadata"
         payload['style'] = "#{Settings.tracksys_url}/api/stylesheet/user?uuid=#{xsl_uuid}"
         response = RestClient.post(Settings.saxon_url, payload)
         if response.code == 200
            new_xml = response.body
         else
            puts "SERVLET ERROR RESPONSE: #{response.body}"
            return
         end

         puts "RESULT ENCODING: [#{new_xml.encoding}]"
         puts "SOURCE ENCODING: [#{md.desc_metadata.encoding}]"
         puts "Check for changes....."
         puts Diffy::Diff.new(new_xml, md.desc_metadata, diff: ["-w","-U10000"]).to_s()
         puts "==== DONE"
      rescue Exception => e
         puts "EXCEPTION: #{e.message}"
      end
   end

   def transform_all(user, xsl_file, comment)
      xsl_uuid = File.basename(xsl_file, ".xsl")
      logger.info "The UUID for this transform is #{xsl_uuid}"
      XmlMetadata.all.find_each do |md|
         next if md.metadata_versions.where(version_tag: xsl_uuid).exists?

         if Settings.use_saxon_servlet == "true"
            new_xml = servlet_transform(md, xsl_uuid)
         else
            new_xml = local_transform(md, xsl_file)
         end
         if MetadataVersion.has_changes? new_xml, md.desc_metadata
            MetadataVersion.create(metadata: md, staff_member: user, desc_metadata:  md.desc_metadata,
               version_tag: xsl_uuid, comment: comment)
            md.update(desc_metadata: new_xml)
         else
            logger.info "Transform XmlMetadata #{mf.metadata.id} : #{mf.metadata.pid} not successful, or caused no changes"
         end
      end
   end

   def servlet_transform(metadata, xsl_uuid)
      payload = {}
      payload['source'] = "#{Settings.tracksys_url}/api/metadata/#{metadata.pid}?type=desc_metadata"
      payload['style'] = "#{Settings.tracksys_url}/api/stylesheet/user?uuid=#{xsl_uuid}"
      begin
         response = RestClient.post(Settings.saxon_url, payload)
         if response.code == 200
            return response.body
         else
            return ""
         end
      rescue Exception => e
         logger.info "Transform XmlMetadata #{metadata.id} : #{metadata.pid} exception: #{e.message}"
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
