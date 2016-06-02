# This module provides methods for exporting metadata to various standard XML
# formats.
module Hydra
   require 'open-uri'
   require 'builder'

   XML_FILE_CREATION_STATEMENT = "Created programmatically by the Digital Curation Services Tracking System."

   #-----------------------------------------------------------------------------

   # Create SOLR <add><doc> for all types of objects
   def self.solr(object)
      if object.is_a? Bibl

         # Create two String variables that hold the total data of a Bibl records' transcriptions and staff_notes
         total_transcription = String.new
         total_description = String.new
         total_title = String.new
         object.dl_master_files.each do |mf|
            total_transcription << mf.transcription_text + " " unless mf.transcription_text.nil?
            total_description << mf.staff_notes + " " unless mf.staff_notes.nil?
            total_title << mf.name_num + " " unless mf.name_num.nil?
         end
         external_relations = "#{FEDORA_REST_URL}/objects/#{object.pid}/datastreams/RELS-EXT/content"
         external_relations = external_relations.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ')

         # total_transcription = total_transcription.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ')
         # total_description = total_description.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ')
         # total_title = total_title.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ')

         analog_solr_record = "http://#{SOLR_PRODUCTION_NAME}/core/select?q=id%3A#{object.catalog_key}"

         if object.availability_policy_id == 1
            availability_policy_pid = false
         else
            availability_policy_pid = object.availability_policy.pid
         end

         shadowed = nil
         if ! object.discoverability
            shadowed = "HIDDEN"
         else
            shadowed = "VISIBLE"
         end

         # if there is a collection_facet, pass it thru to XSLT as a param
         collectionFacetParam = object.collection_facet.nil? ? "NO_PARAM" : "digitalCollectionFacet"

         uri = URI("http://#{SAXON_URL}:#{SAXON_PORT}/saxon/SaxonServlet")
         response = Net::HTTP.post_form(uri, {
            "source" => "#{FEDORA_REST_URL}/objects/#{object.pid}/datastreams/descMetadata/content",
            "style" => "#{object.indexing_scenario.complete_url}",
            "repository" => "#{FEDORA_PROXY_URL}",
            "destination" => "#{Settings.index_destination}",
            "pid" => "#{object.pid}",
            "analogSolrRecord" => "#{analog_solr_record}",
            "dateIngestNow" => "#{Time.now.strftime('%Y%m%d%H')}",
            "dateReceived" => "#{object.date_dl_ingest.strftime('%Y%m%d%H')}",
            "contentModel" => "digital_book",
            "sourceFacet" => "UVA Library Digital Repository",
            "shadowedItem" => "#{shadowed}",
            "externalRelations" => "#{external_relations}",
            collectionFacetParam => "#{object.collection_facet}",
            "totalTitles" => "#{total_title}",
            "totalDescriptions" => "#{total_description}",
            "policyFacet" => "#{availability_policy_pid}",
            "clear-stylesheet-cache" => "yes"
            })
            Rails.logger.info( "Hydra.solr(bibl): SAXON_SERVLET response: #{response.to_s}" )
            return response.body if response.is_a? Net::HTTPSuccess  # doesn't fix issue #194 if bad XML, but it's another sanity check.
         elsif object.is_a? MasterFile
            parent_mods_record = "#{FEDORA_REST_URL}/objects/#{object.bibl.pid}/datastreams/descMetadata/content"
            parent_mods_record = parent_mods_record.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ')

            external_relations = "#{FEDORA_REST_URL}/objects/#{object.pid}/datastreams/RELS-EXT/content"
            external_relations = external_relations.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ')

            analog_solr_record = "http://#{SOLR_PRODUCTION_NAME}/solr/core/select?q=id%3A#{object.bibl.catalog_key}"
            total_transcription = object.transcription_text.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ') unless object.transcription_text.blank?
            total_description = object.description.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ') unless object.description.blank?
            total_title = object.title.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ') unless object.title.blank?

            if object.availability_policy_id == 1
               availability_policy_pid = false
            elsif object.availability_policy
               availability_policy_pid = object.availability_policy.pid
            else
               availability_policy_pid = false
            end

            indexing_scenario_url = IndexingScenario.first.complete_url # default
            if object.indexing_scenario
               indexing_scenario_url = object.indexing_scenario.complete_url
            end

            date_received = Time.now.strftime('%Y%m%d%H')
            if object.date_dl_ingest
               date_received = object.date_dl_ingest.strftime('%Y%m%d%H')
            end


            uri = URI("http://#{SAXON_URL}:#{SAXON_PORT}/saxon/SaxonServlet")
            response = Net::HTTP.post_form(uri, {
               "source" => "#{FEDORA_REST_URL}/objects/#{object.pid}/datastreams/descMetadata/content",
               "style" => "#{indexing_scenario_url}",
               "repository" => "#{FEDORA_PROXY_URL}",
               "destination" => "#{Settings.index_destination}",
               "pid" => "#{object.pid}",
               "analogSolrRecord" => "#{analog_solr_record}",
               "dateIngestNow" => "#{Time.now.strftime('%Y%m%d%H')}",
               "dateReceived" => "#{date_received}",
               "contentModel" => "jp2k",
               "sourceFacet" => "UVA Library Digital Repository",
               "externalRelations" => "#{external_relations}",
               "totalTranscriptions" => "#{total_transcription}",
               "totalTitles" => "#{total_title}",
               "totalDescriptions" => "#{total_description}",
               "parentModsRecord" => "#{parent_mods_record}",
               "policyFacet" => "#{availability_policy_pid}",
               "clear-stylesheet-cache" => "yes"
               })
               return response.body
            elsif object.is_a? Component
               # Return the response from the getIndexingMetadata Fedora Disseminator
               return open("#{FEDORA_REST_URL}/objects/#{object.pid}/methods/uva-lib%3AindexableSDef/getIndexingMetadata?released_facet=#{Settings.index_destination}").read
            else
               raise "Unexpected object type passed to Hydra.solr.  Please inspect code"
            end
            return @solr
         end

         #-----------------------------------------------------------------------------

         # Takes a Bibl, Component, or MasterFile record and returns a string
         # containing descriptive metadata, in the form of a MODS XML document. See
         # http://www.loc.gov/standards/mods/
         #
         # By default, all Units associated with the Bibl are exported. Optionally
         # takes an array of Unit records which serves as a filter for the Units to
         # be exported; that is, a Unit must be included in the array passed to be
         # included in the export.
         def self.desc(object, units_filter = nil)
            # If there is a Bibl with MARC XML available, that MARC XML will be transformed into
            # the MODS that will be ingested as the Hydra-compliant descMetadata
            if object.is_a? Bibl and object.catalog_key
               # Need to modify the output of mods_from_marc to include local identifier used to determine
               # discoverablity in the index.
               doc = Nokogiri::XML(mods_from_marc(object))
               last_node = doc.xpath("//mods:mods/mods:location").last

               # Add node for indexing
               index_node = Nokogiri::XML::Node.new "identifier", doc
               index_node['type'] = 'uri'
               index_node['displayLabel'] = 'Accessible index record displayed in VIRGO'
               index_node['invalid'] = 'yes' unless object.discoverability
               index_node.content = "#{object.pid}"
               last_node.add_next_sibling(index_node)

               # Add node with Fedora PID
               pid_node = Nokogiri::XML::Node.new "identifier", doc
               pid_node['type'] = 'pid'
               pid_node['displayLabel'] = 'UVA Library Fedora Repository PID'
               pid_node.content = "#{object.pid}"
               last_node.add_next_sibling(pid_node)

               # Add node with Tracksys Bibl ID
               bibl_id_node = Nokogiri::XML::Node.new "identifier", doc
               bibl_id_node['type'] = 'local'
               bibl_id_node['displayLabel'] = 'Digital Production Group Tracksys Bibl ID'
               bibl_id_node.content = "#{object.id}"
               last_node.add_next_sibling(bibl_id_node)

               # Add nodes with Legacy Identifier information, if any
               if not object.legacy_identifiers.empty?
                  object.legacy_identifiers.each {|li|
                     li_node = Nokogiri::XML::Node.new "identifier", doc
                     li_node['type'] = 'legacy'
                     li_node['displayLabel'] = "#{li.description}"
                     li_node.content = "#{li.legacy_identifier}"
                     last_node.add_next_sibling(li_node)
                  }
               end

               # Add nodes with Unit IDs that are included in DL
               object.units.each {|unit|
                  if unit.include_in_dl == true
                     unit_id_node = Nokogiri::XML::Node.new "identifier", doc
                     unit_id_node['type'] = 'local'
                     unit_id_node['displayLabel'] = 'Digital Production Group Tracksys Unit ID'
                     unit_id_node.content = "#{unit.id}"
                     last_node.add_next_sibling(unit_id_node)
                  end
               }

               output = doc.to_xml
            else
               output = ''
               xml = Builder::XmlMarkup.new(:target => output, :indent => 2)
               xml.instruct! :xml  # Include XML declaration

               if object.is_a? Bibl
                  mods_bibl(xml, object, units_filter)
               else
                  xml.mods(:mods,
                  "xmlns:mods".to_sym => Fedora_namespaces['mods'],
                  "xmlns:xsi".to_sym => Fedora_namespaces['xsi'],
                  "xsi:schemaLocation".to_sym => Fedora_namespaces['mods'] + ' ' + Schema_locations['mods']
                  ) do
                     if object.is_a? Component
                        mods_component(xml, object)
                     elsif object.is_a? MasterFile
                        mods_master_file(xml, object)
                     end
                  end
               end
            end
            return output
         end

         def self.mods_from_marc(object)
            xslt_str = File.read("#{Rails.root}/lib/xslt/MARC21slim2MODS3-4.xsl")
            i0 = xslt_str.index "<xsl:include"
            i1 = xslt_str.index("\n", i0)
            inc = "<xsl:include href=\"#{Rails.root}/lib/xslt/MARC21slimUtils.xsl\"/>"
            fixed = "#{xslt_str[0...i0]}#{inc}#{xslt_str[i1+1...-1]}"
            xslt = Nokogiri::XSLT(fixed)
            xml = Nokogiri::XML(open("http://search.lib.virginia.edu/catalog/#{object.catalog_key}.xml"))
            mods = xslt.transform(xml, ['barcode', "'#{object.barcode}'"])

            # In order to reformat and pretty print the MODS record after string insertion, the document is reopened and then
            # manipulated by Nokogiri.
            doc = Nokogiri.XML(mods.to_xml) do |config|
               config.default_xml.noblanks
            end
            return doc.to_xml
         end


         # Outputs descriptive metadata for a Bibl record as a MODS document
         def self.mods_bibl(xml, bibl, units_filter)
            # start <mods:mods> element
            xml.mods(:mods,
            "xmlns:mods".to_sym => Fedora_namespaces['mods'],
            "xmlns:xsi".to_sym => Fedora_namespaces['xsi'],
            "xsi:schemaLocation".to_sym => Fedora_namespaces['mods'] + ' ' + Schema_locations['mods']
            ) do

               # Put PID for object into MODS.  In order to transform this into a SOLR doc, there must be a PID in the MODS.
               xml.mods :identifier, bibl.pid, :type =>'pid', :displayLabel => 'UVA Library Fedora Repository PID'

               # Create an identifier statement that indicates whether this item will be uniquely discoverable in VIRGO.  Default for an individual bibl will be to
               # display the SOLR record (i.e. no 'invalid' attribute).  Will draw value from bibl.discoverability.
               if bibl.discoverability
                  xml.mods :identifier, bibl.pid, :type =>'uri', :displayLabel => 'Accessible index record displayed in VIRGO'
               else
                  xml.mods :identifier, bibl.pid, :type =>'uri', :displayLabel => 'Accessible index record displayed in VIRGO', :invalid => 'yes'
               end

               # type of resource
               if bibl.is_manuscript? and bibl.is_collection?
                  xml.mods :typeOfResource, bibl.resource_type, :manuscript => 'yes', :collection => 'yes'
               elsif bibl.is_manuscript?
                  xml.mods :typeOfResource, bibl.resource_type, :manuscript => 'yes'
               elsif bibl.is_collection?
                  xml.mods :typeOfResource, bibl.resource_type, :collection => 'yes'
               else
                  xml.mods :typeOfResource, bibl.resource_type
               end

               # genre
               unless bibl.genre.blank?
                  xml.mods :genre, bibl.genre, :authority => 'marcgt'
               end

               # title
               unless bibl.title.blank?
                  xml.mods :titleInfo do
                     xml.mods :title, bibl.title
                  end
               end

               # description
               unless bibl.description.blank?
                  xml.mods :abstract, bibl.description
               end

               # creator
               unless bibl.creator_name.blank?
                  if bibl.creator_name_type.blank?
                     # omit 'type' attribute
                     xml.mods :name do
                        xml.mods :namePart, bibl.creator_name
                     end
                  else
                     # include 'type' attribute
                     xml.mods :name, :type => bibl.creator_name_type do
                        xml.mods :namePart, bibl.creator_name
                     end
                  end
               end

               mods_originInfo(xml, bibl, units_filter)
               mods_physicalDescription(xml, bibl, units_filter)
               mods_location(xml, bibl)
               mods_recordInfo(xml, bibl)
            end  # </mods:mods>
         end
         private_class_method :mods_bibl

         #-----------------------------------------------------------------------------

         # Outputs a Component record as a +mods:relatedItem+ element
         def self.mods_component(xml, component)
            if component.seq_number.blank?
               display_label = component.component_type.name.capitalize
            else
               display_label = "#{component.component_type.name.capitalize} #{component.seq_number}"
            end

            if component.pid.blank?
               relatedItem_id = "component_#{component.id}"
            else
               relatedItem_id = format_pid(component.pid)
            end

            # title
            unless component.title.blank?
               xml.mods :titleInfo do
                  xml.mods :title, component.title
               end
            end

            # label
            unless component.label.blank? or component.label == component.title
               xml.mods :titleInfo do
                  xml.mods :title, component.label
               end
            end

            # date
            unless component.date.blank?
               xml.mods :originInfo do
                  xml.mods :dateCreated, component.date, :keydate => 'yes', :encoding => "w3cdtf"
               end
            end

            # content description
            unless component.content_desc.blank?
               xml.mods :abstract, component.content_desc
            end

            # identifiers
            unless component.idno.blank?
               xml.mods :identifier, component.idno, :type => 'local', :displayLabel => 'Local identifier'
            end
            unless component.barcode.blank?
               xml.mods :identifier, component.barcode, :type => 'local', :displayLabel => 'Barcode'
            end

            # # Include each associated MasterFile as a nested <mods:atedItem>
            # count = 0
            # component.master_files.sort_by{|mf| mf.filename}.each do |master_file|
            #   count += 1
            #   mods_master_file(xml, master_file, count)
            # end

            # # Output each child Component as a nested <mods:relatedItem>
            # component.childr  en.each do |child_component|
            #   mods_component(xml, child_component)
            # end
         end
         private_class_method :mods_component

         #-----------------------------------------------------------------------------

         # Outputs a +mods:location+ element
         def self.mods_location(xml, bibl)
            xml.mods :location do
               if bibl.is_personal_item
                  xml.mods :physicalLocation, '[personal copy]'
               else
                  #xml.mods :physicalLocation, 'University of Virginia Library'
                  xml.mods :physicalLocation, 'viu', :authority => 'marcorg'
               end

               xml.mods :url, @xml_file_name, :usage => 'primary display', :access => 'object in context'

               unless bibl.copy.blank?
                  xml.mods :holdingSimple do
                     xml.mods :copyInformation do
                        xml.mods :enumerationAndChronology, "copy #{bibl.copy}"
                     end
                  end
               end
            end
         end
         private_class_method :mods_location

         #-----------------------------------------------------------------------------

         # Outputs a MasterFile record as a +mods:relatedItem+ element
         def self.mods_master_file(xml, master_file, count = nil)

            # Put PID for object into MODS.  In order to transform this into a SOLR doc, there must be a PID in the MODS.
            xml.mods :identifier, master_file.pid, :type =>'pid', :displayLabel => 'UVA Library Fedora Repository PID'

            # Create an identifier statement that indicates whether this item will be uniquely discoverable in VIRGO.  Default for an individual master_file will be to
            # hide the SOLR record (i.e. make :invalid => 'yes').  Will draw value from master_file.discoverability.
            if master_file.discoverability
               xml.mods :identifier, master_file.pid, :type =>'uri', :displayLabel => 'Accessible index record displayed in VIRGO'
            else
               xml.mods :identifier, master_file.pid, :type =>'uri', :displayLabel => 'Accessible index record displayed in VIRGO', :invalid => 'yes'
            end

            xml.mods :identifier, master_file.unit.id, :type => 'local', :displayLabel => 'Digital Production Group Tracksys Unit ID'

            xml.mods :identifier, master_file.id, :type => 'local', :displayLabel => 'Digital Production Group Tracksys MasterFile ID'

            xml.mods :identifier, master_file.filename, :type => 'local', :displayLabel => 'Digital Production Group Archive Filename'

            if not master_file.legacy_identifiers.empty?
               master_file.legacy_identifiers.each {|li|
                  xml.mods :identifier, "#{li.legacy_identifier}", :type => 'legacy', :displayLabel => "#{li.description}"
               }
            end

            case master_file.tech_meta_type
            when 'image'
               display_label = "Image"
            when 'text'
               display_label = "#{master_file.text_tech_meta.text_format} text resource"
            else
               raise "Unexpected tech_meta_type value '#{master_file.tech_meta_type}' on master_file #{master_file.id}"
            end

            if master_file.pid.blank?
               relatedItem_id = "#{master_file.tech_meta_type}_#{master_file.id}"
            else
               relatedItem_id = format_pid(master_file.pid)
            end

            xml.mods :titleInfo do
               if master_file.name_num.blank?
                  if count.nil?
                     title = "[#{display_label}]"
                  else
                     title = "[#{display_label} #{count}]"
                  end
                  xml.mods :title, title
               else
                  xml.mods :title, master_file.name_num
               end
            end
            if master_file.staff_notes
               xml.mods :note, master_file.staff_notes
            end
         end
         private_class_method :mods_master_file

         #-----------------------------------------------------------------------------

         # Outputs a +mods:originInfo+ element
         def self.mods_originInfo(xml, bibl, units_filter)
            xml.mods :originInfo do
               # date captured (date of digitization)
               # Looking at the units associated with this bibl record, use the latest
               # date_completed value.
               date_completed = nil
               bibl.units.each do |unit|
                  next if units_filter.is_a? Array and ! units_filter.include? unit
                  if not unit.date_archived.blank?
                     if date_completed.blank?
                        date_completed = unit.date_archived
                     elsif unit.date_archived > date_completed
                        date_completed = unit.date_archived
                     end
                  end
               end
               unless date_completed.blank?
                  xml.mods :dateCaptured, date_completed.strftime("%Y-%m-%d")
               end

               # publisher of digital resource
               xml.mods :publisher, 'University of Virginia Library'
               xml.mods :place do
                  xml.mods :placeTerm, 'Charlottesville, VA'
               end
            end
         end
         private_class_method :mods_originInfo

         #-----------------------------------------------------------------------------

         # Outputs a +mods:physicalDescription+ element
         def self.mods_physicalDescription(xml, bibl, units_filter)
            xml.mods :physicalDescription do
               # Determine extent -- that is, number of files. First preference is to count
               # MasterFile records associated with this bibl record; second is
               # unit_extent_actual value; last resort is unit_extent_estimated value.
               c = 0
               bibl.units.each do |unit|
                  next if units_filter.is_a? Array and ! units_filter.include? unit
                  if unit.master_files.size > 0
                     c += unit.master_files.size
                  elsif unit.unit_extent_actual.to_i > 0
                     c += unit.unit_extent_actual
                  elsif unit.unit_extent_estimated.to_i > 0
                     c += unit.unit_extent_estimated
                  end
               end
               xml.mods :extent, c.to_s + ' ' + (c == 1 ? 'file' : 'files') if c > 0

               # <digitalOrigin> uses a controlled vocabulary; use "reformatted digital"
               # meaning "resource was created by digitization of the original non-digital
               # form" (MODS documentation).
               xml.mods :digitalOrigin, 'reformatted digital'

               # List the mime types applicable to this bibl record (based on the
               # MasterFile records associated with this bibl record).
               # build hash of mime types
               mime_types = Hash.new
               bibl.units.each do |unit|
                  next if units_filter.is_a? Array and ! units_filter.include? unit
                  unit.master_files.each do |master_file|
                     mime_types[master_file.mime_type] = nil
                  end
               end
               # output list of mime types
               mime_types.each_key do |mime_type|
                  xml.mods :internetMediaType, mime_type
               end
            end
         end
         private_class_method :mods_physicalDescription

         #-----------------------------------------------------------------------------

         # Outputs a +mods:recordInfo+ element
         def self.mods_recordInfo(xml, bibl)
            xml.mods :recordInfo do
               # organization that created this MODS metadata record
               xml.mods :recordContentSource, 'viu', :authority => 'marcorg'

               # creation date for this MODS metadata record
               xml.mods :recordCreationDate, Time.now.strftime("%Y%m%d"), :encoding => 'w3cdtf'

               # origin of this MODS metadata record
               xml.mods :recordOrigin, XML_FILE_CREATION_STATEMENT

               # language of this MODS metadata record (English)
               xml.mods :languageOfCataloging do
                  xml.mods :languageTerm, 'en', :type => 'code', :authority => 'rfc3066'
               end
            end
         end
         private_class_method :mods_recordInfo

         #-------------------------------------------------------------------------------
         # Utility methods
         #-------------------------------------------------------------------------------

         # Formats a PID (e.g. "uva-lib:123") for use in ID attribute values within a
         # METS, MODS, etc. document. Replaces colon with underscore by default, or
         # replacement string if passed.
         #
         # A colon in the value of an ID attribute is allowed by the XML
         # specification, but not by the NCName (noncolonized name) datatype used in
         # W3C XML Schema datatypes. Since the METS, MODS, etc. schema are in W3C XML
         # Schema form, using colons in ID attributes produces documents that are
         # well-formed but not valid. To produce valid output, replace the colon.
         def self.format_pid(pid, replacement = '_')
            return pid.gsub(/:/, replacement)
         end
         private_class_method :format_pid
      end
