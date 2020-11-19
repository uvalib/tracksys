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
         new_xml = servlet_transform(mf.metadata, xsl_uuid)

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

         new_xml = servlet_transform(md, xsl_uuid)

         if MetadataVersion.has_changes? new_xml, md.desc_metadata
            MetadataVersion.create(metadata: md, staff_member: user, desc_metadata:  md.desc_metadata,
               version_tag: xsl_uuid, comment: comment)
            md.update(desc_metadata: new_xml)
         else
            logger.info "Transform XmlMetadata #{md.id} : #{md.pid} not successful, or caused no changes"
         end
      end
   end

   def servlet_transform(metadata, xsl_uuid)
      payload = {}
      payload['source'] = "#{Settings.tracksys_url}/api/metadata/#{metadata.pid}?type=mods"
      payload['style'] = "#{Settings.tracksys_url}/api/stylesheet/user?uuid=#{xsl_uuid}"
      begin
         response = RestClient.post(Settings.saxon_url, payload)
         if response.code == 200
            xml_str = response.body
            # Detect non-utf-8 encoding and see if it was set in error
            # by forcing encoding flag to utf8 (without changing the string)
            if xml_str.encoding.name != "UTF-8"
               old_enc = xml_str.encoding.name
               logger.info "Detected non-UTF-8 encoding #{old_enc}. Try to change flag"
               xml_str.force_encoding("UTF-8")
               if !xml_str.valid_encoding?
                  # Not valid. Switch back to old encoding and
                  # try to transcode to utf8
                  logger.info "Flag change failed; try to transcode to UTF-8 instead"
                  xml_str.force_encoding(old_enc)
                  xml_str = xml_str.encode("UTF-8")
               end
               logger.info "Response is now UTF-8"
            end
            return xml_str
         else
            return ""
         end
      rescue Exception => e
         logger.info "Transform XmlMetadata #{metadata.id} : #{metadata.pid} exception: #{e.message}"
         return ""
      end
   end
end
