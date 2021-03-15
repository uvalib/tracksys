# This module provides methods for exporting metadata to various standard XML formats.
#
module Hydra

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
         mods_xml_string = mods_from_marc(sirsi_metadata)
         if mods_xml_string == ""
            Rails.logger.error("Conversion of MARC to MODS for #{metadata.pid} returned an empty string")
            return ""
         end

         doc = Nokogiri::XML( mods_xml_string)
         namespaces = doc.root.namespaces
         if namespaces.key?("mods") == false
            doc.root.add_namespace_definition("mods", "http://www.loc.gov/mods/v3")
         end
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
            add_access_url_to_mods(doc, metadata)
         end
         output = doc.to_xml
      else
         # For now, the only type of metadata that exists is MODS XML. Just return it
         # TODO this will need to be updated when ASpace metadata is supported, and
         # when other flavors of XML are supported (VRA, others)

         doc = Nokogiri::XML(metadata.desc_metadata)
         add_rights_to_mods(doc, metadata)
         add_access_url_to_mods(doc, metadata)
         output = doc.to_xml
      end
      return output
   end

   # Generate mods from sirsi metadata
   #
   def self.mods_from_marc(object)
      uri = URI(Settings.saxon_url)

      # Do this in two passes. First pass is a transform that corrects known problems in the MARC
      Rails.logger.info "Run fixMarcErrors.xsl to cleanup metadata prior to transform to MODS on #{object.pid}"
      payload = {}
      payload['source'] = "#{Settings.tracksys_url}/api/metadata/#{object.pid}?type=marc"
      payload['style'] = "#{Settings.tracksys_url}/api/stylesheet/fixmarc"
      payload['clear-stylesheet-cache'] = "yes"
      response = Net::HTTP.post_form(uri, payload)
      if response.code.to_i != 200
         # the fix failed... just run the transform to MODS on the original MARC
         Rails.logger.error "Fix MARC #{object.pid} failed with code #{response.code}: #{response.body}"
         payload['source'] = "#{Settings.tracksys_url}/api/metadata/#{object.pid}?type=marc"
      else
         # write the fixed up MARC to a temp location
         out_dir = File.join(Rails.root, "tmp", "fixed_marc")
         if !Dir.exist? out_dir
            FileUtils.mkdir_p out_dir
         end
         out_file = File.join(out_dir, "#{object.pid}.xml")
         File.open(out_file, 'wb') { |file| file.write(response.body) }
         payload['source'] = "#{Settings.tracksys_url}/api/metadata/#{object.pid}?type=fixedmarc"
         Rails.logger.info "Fix MARC #{object.pid} success"
      end


      # Now, tke the fixed MARC an transform it
      payload['barcode'] = object.barcode
      payload['style'] = "#{Settings.tracksys_url}/api/stylesheet/marctomods"
      response = Net::HTTP.post_form(uri, payload)
      Rails.logger.info( "Hydra.mods_from_marc: SAXON_SERVLET response: #{response.code} #{response.body}" )
      return response.body if response.code.to_i == 200
      return ""
   end

   def self.add_rights_to_mods(doc, metadata)
      namespaces = doc.root.namespaces
      if namespaces.key?("xlink") == false
         doc.root.add_namespace_definition("xlink", "http://www.w3.org/1999/xlink")
      end
      if namespaces.key?("mods") == false
         doc.root.add_namespace_definition("mods", "http://www.loc.gov/mods/v3")
      end
      access = doc.xpath("//mods:mods/mods:accessCondition").first
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

   def self.add_access_url_to_mods(doc, metadata)
      namespaces = doc.root.namespaces
      if namespaces.key?("mods") == false
         doc.root.add_namespace_definition("mods", "http://www.loc.gov/mods/v3")
      end

      # generate all of the necessary URL nodes
      url_nodes = []
      n = Nokogiri::XML::Node.new "url", doc
      n['access'] = 'object in context'
      n.content = "#{Settings.virgo_url}/#{metadata.pid}"
      url_nodes << n
      if metadata.has_exemplar?
         n = Nokogiri::XML::Node.new "url", doc
         n['access'] = 'preview'
         n.content = metadata.exemplar_info(:small)[:url]
         url_nodes << n
      end
      n = Nokogiri::XML::Node.new "url", doc
      n['access'] = 'raw object'
      n.content = "#{Settings.doviewer_url}/view/#{metadata.pid}"
      url_nodes << n

      loc = doc.xpath("//mods:mods/mods:location").first
      if loc.nil?
         # no location node present, just add one at start and append the
         # URL nodes from above to it
         ln = Nokogiri::XML::Node.new "location", doc
         doc.root.children.first.add_previous_sibling(ln)
         url_nodes.each do |n|
            ln.add_child(n)
         end
      else
         # Location is present. URLs must be added AFTER physicalLocation
         pl = loc.xpath("mods:physicalLocation").first
         if pl.nil?
            # No physicalLocation, just add to root of location
            url_nodes.each do |n|
               loc.add_child(n)
            end
         else
            # physicalLocation found, add URL nodes immediately after
            url_nodes.each do |n|
               pl.add_next_sibling(n)
            end
         end
      end
   end
end
