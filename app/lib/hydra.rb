# This module provides methods for exporting metadata to various standard XML formats.
#
module Hydra

   # Create SOLR <add><doc> for metadata objects
   def self.solr(metadata, no_external)
      raise "Not availble for SirsiMetadata records" if metadata.type!="XmlMetadata"

      # init common parameter values
      payload = {}
      now_str = Time.now.strftime('%Y%m%d%H')
      date_received = now_str
      date_received = metadata.date_dl_ingest.strftime('%Y%m%d%H') if !metadata.date_dl_ingest.blank?

      # Build payload for transformation
      if !no_external.nil?
         # hack to allow a call to this from the iiif service. Without it
         # recursive calls happen as the XSLT calls back to tracksys
         payload["excludeExternallyGenerated"] = 1
      end
      payload["pid"] = "#{metadata.pid}"
      payload["destination"] = "#{Settings.index_destintion}"
      payload["dateReceived"] = "#{date_received}"
      payload["dateIngestNow"] = "#{now_str}"
      payload["sourceFacet"] = "UVA Library Digital Repository"
      payload["iiifManifest"] = "#{Settings.iiif_manifest_url}/#{metadata.pid}/manifest.json"
      payload["iiifRoot"] = "#{Settings.iiif_url}/"
      payload["rightsWrapperServiceUrl"] = "#{Settings.rights_wrapper_url}?pid=#{metadata.pid}&pagePid="
      payload["useRightsString"] = "#{metadata.use_right.name}"
      payload["permanentUrl"] = "#{Settings.virgo_url}/#{metadata.pid}"
      payload["transcriptionUrl"] = "#{Settings.tracksys_url}/api/fulltext/#{metadata.pid}?type=transcription"
      payload["descriptionUrl"] = "#{Settings.tracksys_url}/api/fulltext/#{metadata.pid}?type=description"

      payload["shadowedItem"] = "HIDDEN"
      if metadata.discoverability
         payload["shadowedItem"] = "VISIBLE"
      end

      # Hack to hide jefferson papers stuff (order 2575)
      good_pids = ["uva-lib:760484", "uva-lib:710304"]
      if not good_pids.include? metadata.pid
         if metadata.orders.where(id: 2575).count > 0
            payload["shadowedItem"] = "HIDDEN"
         end
      end

      collectionFacetParam = metadata.collection_facet.nil? ? "NO_PARAM" : "digitalCollectionFacet"
      payload[collectionFacetParam] = metadata.collection_facet
      payload["pdfServiceUrl"] = "#{Settings.pdf_url}"
      if metadata.availability_policy_id == 1 || metadata.availability_policy_id.blank?
         availability_policy_pid = false
      else
         availability_policy_pid = metadata.availability_policy.pid
      end
      payload["policyFacet"] = "#{availability_policy_pid}"
      if metadata.has_exemplar?
         payload["exemplarPid"] = metadata.exemplar_info[:pid]
      else
         # one not set; just pick the first masterfile
         payload["exemplarPid"] = "#{metadata.master_files.first.pid}" if !metadata.master_files.first.nil?
      end

      # Create string variables that hold the total data of a metadata records' transcriptions, descriptions and titles
      payload["totalTitles"] = ""
      mf_cnt = 0
      metadata.dl_master_files.each do |mf|
         payload["totalTitles"] << mf.title + " " unless mf.title.nil?
         mf_cnt += 1
      end
      payload["pageCount"] = mf_cnt.to_s
      payload["totalTitles"] = payload["totalTitles"].gsub(/\s+/, ' ').strip

      if metadata.type == "SirsiMetadata"
         sirsi_metadata = metadata.becomes(SirsiMetadata)
         payload["analogSolrRecord"] = "#{Settings.solr_url}/core/select?q=id%3A#{sirsi_metadata.catalog_key}"
      end

      return solr_transform(metadata, payload)
   end

   def self.solr_transform(metadata, payload)
      if Settings.use_saxon_servlet == "true"
         ok, xml = Hydra.servlet_transform(metadata, payload)
      else
         ok, xml = Hydra.local_transform(metadata, payload)
      end
      return ok, xml
   end

   def self.servlet_transform(metadata, payload)
      # TODO for now there is only 1 XML format supported (MODS) and one
      # transform. When this changes, the code here will need to be updated
      payload['source'] = "#{Settings.tracksys_url}/api/metadata/#{metadata.pid}?type=desc_metadata"
      payload['style'] = "#{Settings.tracksys_url}/api/stylesheet/holsinger"
      payload['clear-stylesheet-cache'] = "yes"

      uri = URI(Settings.saxon_url)
      response = Net::HTTP.post_form(uri, payload)
      Rails.logger.info( "Hydra.solr(bibl): SAXON_SERVLET response: #{response.code} #{response.body}" )
      return response.code.to_i == 200, response.body
   end

   def self.local_transform(metadata, payload)
      tmp = Tempfile.new([metadata.pid, ".xml"])
      tmp.write(Hydra.desc(metadata))
      tmp.close

      # TODO for now there is only 1 XML format supported (MODS) and one
      # transform. When this changes, the code here will need to be updated
      xsl = File.join(Rails.root, "lib", "xslt", "holsingerTransformation.xsl")
      saxon = "java -jar #{File.join(Rails.root, "lib", "Saxon-HE-9.7.0-8.jar")}"

      params = ""
      payload.each do |k,v|
         next if v.blank?
         v.strip!
         if v.include? "'"
            params << " #{k}=\"#{v}\""
         else
            params << " #{k}='#{v}'"
         end
      end

      cmd = "#{saxon} -s:#{tmp.path} -xsl:#{xsl} #{params}"
      return true, `#{cmd}`
   end

   #-----------------------------------------------------------------------------

   # Takes a Metadata Record or MasterFile record and returns a string
   # containing descriptive metadata, in the form of a MODS XML document. See
   # http://www.loc.gov/standards/mods/
   #
   def self.desc(object)
      metadata = object
      metadata object.metadata if object.is_a? MasterFile
      if metadata.type == "SirsiMetadata"
         # transform MARC XML will into
         # the MODS that will be ingested as the Hydra-compliant descMetadata
         sirsi_metadata = object.becomes(SirsiMetadata)
         doc = Nokogiri::XML( mods_from_marc(sirsi_metadata) )
         doc.root.add_namespace_definition("mods", "http://www.loc.gov/mods/v3")
         last_node = doc.xpath("//mods:mods/mods:recordInfo").last
         if !last_node.nil?
            # Add node for indexing
            index_node = Nokogiri::XML::Node.new "identifier", doc
            index_node['type'] = 'uri'
            index_node['displayLabel'] = 'Accessible index record displayed in VIRGO'
            index_node['invalid'] = 'yes' unless object.discoverability
            index_node.content = "#{metadata.pid}"
            last_node.add_next_sibling(index_node)

            # Add node with Tracksys Metadata ID
            metadata_id_node = Nokogiri::XML::Node.new "identifier", doc
            metadata_id_node['type'] = 'local'
            metadata_id_node['displayLabel'] = 'Digital Production Group Tracksys Metadata ID'
            metadata_id_node.content = "#{metadata.id}"
            last_node.add_next_sibling(metadata_id_node)

            # Add nodes with Unit IDs that are included in DL
            metadata.units.each do |unit|
               if unit.include_in_dl == true
                  unit_id_node = Nokogiri::XML::Node.new "identifier", doc
                  unit_id_node['type'] = 'local'
                  unit_id_node['displayLabel'] = 'Digital Production Group Tracksys Unit ID'
                  unit_id_node.content = "#{unit.id}"
                  last_node.add_next_sibling(unit_id_node)
               end
            end
            add_rights_to_mods(doc, metadata)
         end
         output = doc.to_xml
      else
         # For now, the only type of metadata that exists is MODS XML. Just return it
         # TODO this will need to be updated when ASpace metadata is supported, and
         # when other flavors of XML are supported (VRA, others)

         doc = Nokogiri::XML(metadata.desc_metadata)
         add_rights_to_mods(doc, metadata)
         output = doc.to_xml
      end
      return output
   end

   # Generate mods from sirsi metadata
   #
   def self.mods_from_marc(object)
      payload = {}
      payload['barcode'] = object.barcode
      payload['source'] = "#{Settings.tracksys_url}/api/metadata/#{object.pid}?type=marc"
      payload['style'] = "#{Settings.tracksys_url}/api/stylesheet/marctomods"
      payload['clear-stylesheet-cache'] = "yes"
      uri = URI(Settings.saxon_url)
      response = Net::HTTP.post_form(uri, payload)
      Rails.logger.info( "Hydra.mods_from_marc: SAXON_SERVLET response: #{response.code} #{response.body}" )
      return response.body if response.code.to_i == 200
      return ""
   end

   private
   def self.add_rights_to_mods(doc, metadata)
      # some desc_metadata has namespaces, some does not.
      # figure out if this one does, and set params to be used in xpath
      ns = ""
      ns = "mods:" if doc.to_xml.include? "mods:"

      access = doc.xpath("//#{ns}mods/#{ns}accessCondition").first
      if access.nil?
         rights_node = Nokogiri::XML::Node.new "accessCondition", doc
         rights_node['type'] = 'use and reproduction'
         if metadata.use_right.blank?
            rights_node.content = "#{UseRight.fin(1).uri}" # default to CNE
         else
            rights_node.content = "#{metadata.use_right.uri}"
         end
         if !doc.root.nil?
            doc.root.children.first.add_previous_sibling(rights_node)
         end
      end
   end
end
