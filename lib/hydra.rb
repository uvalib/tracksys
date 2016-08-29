# This module provides methods for exporting metadata to various standard XML
# formats.
module Hydra
   require 'open-uri'
   require 'builder'

   XML_FILE_CREATION_STATEMENT = "Created programmatically by the Digital Curation Services Tracking System."

   # Create SOLR <add><doc> for all types of objects
   def self.solr(object)
      # init common parameter values
      payload = {}
      now_str = Time.now.strftime('%Y%m%d%H')
      date_received = now_str
      date_received = object.date_dl_ingest.strftime('%Y%m%d%H') if !object.date_dl_ingest.blank?

      payload["pid"] = "#{object.pid}"
      payload["destination"] = "#{Settings.index_destintion}"
      payload["dateReceived"] = "#{date_received}"
      payload["dateIngestNow"] = "#{now_str}"
      payload["sourceFacet"] = "UVA Library Digital Repository"
      payload["iiifManifest"] = "#{Settings.iiif_manifest_url}/#{object.pid}/manifest.json"
      payload["iiifRoot"] = "#{Settings.iiif_url}/"
      payload["rightsWrapperServiceUrl"] = "#{Settings.rights_wrapper_url}?pid=#{object.pid}&pagePid="
      payload["useRightsString"] = "#{object.use_right.name}"
      payload["style"] = "#{Settings.tracksys_url}/api/style/#{object.indexing_scenario.id}"
      payload["source"] = "#{Settings.tracksys_url}/api/metadata/#{object.pid}?type=desc_metadata"
      payload["permanentUrl"] = "#{Settings.virgo_url}/#{object.pid}"
      payload["clear-stylesheet-cache"] = "yes"

      if object.is_a? Metadata
         collectionFacetParam = object.collection_facet.nil? ? "NO_PARAM" : "digitalCollectionFacet"
         payload[collectionFacetParam] = object.collection_facet
         payload["pageCount"] = object.master_files.count.to_s
         payload["pdfServiceUrl"] = "#{Settings.pdf_url}"
         if object.availability_policy_id == 1 || object.availability_policy_id.blank?
            availability_policy_pid = false
         else
            availability_policy_pid = object.availability_policy.pid
         end
         payload["policyFacet"] = "#{availability_policy_pid}"
         if !object.exemplar.blank?
            payload["exemplarPid"] = "#{MasterFile.find_by(filename: object.exemplar).pid}"
         else
            # one not set; just pick the first masterfile
            payload["exemplarPid"] = "#{object.master_files.first.pid}" if !object.master_files.first.nil?
         end

         # Create string variables that hold the total data of a metadata records' transcriptions, descriptions and titles
         total_transcription = ""
         total_description = ""
         total_title = ""
         object.dl_master_files.each do |mf|
            total_transcription << mf.transcription_text + " " unless mf.transcription_text.nil?
            total_description << mf.description + " " unless mf.description.nil?
            total_title << mf.title + " " unless mf.title.nil?
         end
         total_transcription = total_transcription.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ') unless total_transcription.blank?
         total_description = total_description.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ') unless total_description.blank?
         total_title = total_title.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ') unless total_title.blank?

         payload["analogSolrRecord"] = "#{Settings.solr_url}/core/select?q=id%3A#{object.catalog_key}"
         payload["totalTitles"] = "#{total_title}"
         payload["totalDescriptions"] = "#{total_description}"
         payload["totalTranscriptions"] = "#{total_transcription}"

         if !object.discoverability
            payload["shadowedItem"] = "HIDDEN"
         else
            payload["shadowedItem"] = "VISIBLE"
         end

         return solr_transform(object, payload)
      elsif object.is_a? MasterFile
         if object.metadata.availability_policy_id == 1 || object.metadata.availability_policy_id.blank?
            availability_policy_pid = false
         else
            availability_policy_pid = object.metadata.availability_policy.pid
         end
         payload["policyFacet"] = "#{availability_policy_pid}"
         payload["exemplarPid"] = "#{object.pid}"

         payload["parentModsRecord"] = "#{Settings.tracksys_url}/api/metadata/#{object.metadata.pid}?type=desc_metadata"
         total_transcription = object.transcription_text.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ') unless object.transcription_text.blank?
         total_description = object.description.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ') unless object.description.blank?
         total_title = object.title.gsub(/\r/, ' ').gsub(/\n/, ' ').gsub(/\t/, ' ').gsub(/(  )+/, ' ') unless object.title.blank?
         payload["totalTitles"] = "#{total_title}"
         payload["totalDescriptions"] = "#{total_description}"
         payload["totalTranscriptions"] = "#{total_transcription}"
         if object.metadata.type == "SirsiMetadata"
            sirsi_metadata = object.metadata.becomes(SirsiMetadata)
            payload["analogSolrRecord"] = "#{Settings.solr_url}/core/select?q=id%3A#{sirsi_metadata.catalog_key}"
         end

         return solr_transform(object, payload)
      else
         raise "Unexpected object type passed to Hydra.solr.  Please inspect code"
      end
      return @solr
   end

   def self.solr_transform(object, payload)
      payload.each do |k,v|
         payload[k] = v.gsub(/'/,"")
      end
      uri = URI("http://fedora-staging.lib.virginia.edu:8080/saxon/SaxonServlet")
      response = Net::HTTP.post_form(uri,payload)
      return response.body
   end

   # given the output of an object's solr_xml method, return a solr-ruby object
   def self.read_solr_xml(solr_xml)
      xml = Nokogiri::XML(solr_xml) { |config| config.strict.nonet }  # Issue #194 strict parsing here will throw an error instead of posting BAD xml
      doc = Solr::Document.new

      # The Hash has to be rebuilt at every element so to allow repeatable solr fields (i.e. subject_text).
      xml.xpath("//field").each { |e|
         h = Hash.new
         h[e['name']] = e.content
         doc << h
      }

      return doc
   end

   # Takes Metadata, Component or MasterFile record and returns a string
   # containing metadata indicating external relationships (Fedora RELS-EXT
   # datastream), in the form of an RDF XML document.
   def self.rels_ext(object)
      unless object.respond_to?(:pid)
         raise ArgumentError, "Object passed must have a 'pid' attribute"
      end
      if object.pid.blank?
         raise ArgumentError, "Can't export #{object.class} #{object.id}: pid is blank"
      end

      output = ''
      xml = Builder::XmlMarkup.new(:target => output, :indent => 2)
      xml.instruct! :xml  # Include XML declaration

      xml.rdf(:RDF,
      "xmlns:fedora-model".to_sym => Fedora_namespaces['fedora-model'],
      "xmlns:rdf".to_sym => Fedora_namespaces['rdf'],
      "xmlns:rdfs".to_sym => Fedora_namespaces['rdfs'],
      "xmlns:rel".to_sym => Fedora_namespaces['rel'],
      "xmlns:uva".to_sym => Fedora_namespaces['uva']
      ) do
         xml.rdf(:Description, "rdf:about".to_sym => "info:fedora/#{object.pid}") do

            # Create isMemberof relationship in rels-ext
            # For a Component or MasterFile object, indicate parent/child relationship using <rel:isMemberOf>
            if object.is_a? Component
               if object.parent
                  xml.rel :isPartOf, "rdf:resource".to_sym => "info:fedora/#{object.parent.pid}"
               end
               if object.new_previous
                  xml.uva :follows, "rdf:resource".to_sym => "info:fedora/#{object.new_previous.pid}"
               end
            elsif object.is_a? MasterFile
               if object.component
                  parent_pid = object.component.pid
                  xml.uva :isConstituentOf, "rdf:resource".to_sym => "info:fedora/#{parent_pid}"
               else
                  parent_pid = object.unit.metadata.pid
                  xml.uva :isConstituentOf, "rdf:resource".to_sym => "info:fedora/#{parent_pid}"
                  xml.uva :hasCatalogRecordIn, "rdf:resource".to_sym => "info:fedora/#{parent_pid}"
               end
            elsif object.is_a? Metadata
               if object.parent_bibl
                  parent_pid = object.parent_bibl.pid
                  xml.uva :hasCatalogRecordIn, "rdf:resource".to_sym => "info:fedora/#{parent_pid}"
               end
            else
            end

            if object.is_a? Component
               # Assign visibility status for Components
               if object.discoverability?
                  xml.uva :visibility, 'VISIBLE'
               else
                  xml.uva :visibility, 'UNDISCOVERABLE'
               end

               # Assign MasterFile records to a Component
               if not object.master_files.empty?
                  object.master_files.each {|mf|
                     xml.uva :hasDigitalRepresentation, "rdf:resource".to_sym => "info:fedora/#{mf.pid}"
                  }

                  # lookup exemplar pid or select one
                  exemplar = nil
                  if object.exemplar?
                     exemplar = MasterFile.where(filename: object.exemplar).first
                  else
                     exemplar = object.master_files.first
                  end
                  warn "PID lookup for #{object.class} #{object.id} exemplar returned #{exemplar.pid.to_s}" unless exemplar.pid =~ /^uva-lib:\d+$/
                  xml.uva :hasExemplar, "rdf:resource".to_sym => "info:fedora/#{exemplar.pid}"
               end
            end

            # Acquire PID of image that has been selected as the exemplar image for this record.
            # Exemplar images are used in the Blacklight display on the _index_partial/_dl_jp2k view.
            if object.is_a? Metadata
               if object.exemplar
                  exemplar_master_file = MasterFile.find_by(filename: object.exemplar)
                  if !exemplar_master_file.nil?
                     pid = exemplar_master_file.pid
                     xml.uva :hasExemplar, "rdf:resource".to_sym => "info:fedora/#{pid}"
                  end
               else
                  # Using the mean of the files output from the method in metadata model to get only those masterfiles
                  # associated with this metadata record that belong to units that have already been queued for ingest.
                  #
                  # dl_master_files might return Nil prior to ingest, so we will use the master_files method
                  mean_of_master_files = object.master_files.length / 2
                  pid = object.master_files[mean_of_master_files.to_i].pid

                  # save master file designated as the exemplar to the metadata record
                  object.exemplar = object.master_files[mean_of_master_files.to_i].filename
                  object.save!

                  xml.uva :hasExemplar, "rdf:resource".to_sym => "info:fedora/#{pid}"
               end
            end

            # Create sequential relationships: hasPreceedingPage, hasFollowingPage
            # note that previous/next are based on units; Components should be restricted to self.
            if object.is_a? MasterFile
               if object.previous and ( object.component.nil? or object.component == object.previous.component )
                  xml.uva :hasPreceedingPage, "rdf:resource".to_sym => "info:fedora/#{object.previous.pid}"
                  xml.uva :isFollowingPageOf, "rdf:resource".to_sym => "info:fedora/#{object.previous.pid}"
                  object.previous && object.component && object.component == object.previous.component
               end
               if object.next and ( object.component.nil? or object.component == object.next.component )
                  xml.uva :hasFollowingPage, "rdf:resource".to_sym => "info:fedora/#{object.next.pid}"
                  xml.uva :isPreceedingPageOf, "rdf:resource".to_sym => "info:fedora/#{object.next.pid}"
               end
            end

            # Indicate content model using <fedora-model:hasModel>
            content_models = Array.new
            if object.is_a? Metadata
               content_models.push(Fedora_content_models['fedora-generic'])
               if object.dpla
                  if object.parent_bibl
                     content_models.push(Fedora_content_models['dpla-item'])
                  else
                     content_models.push(Fedora_content_models['dpla-collection'])
                  end
               end
            elsif object.is_a? Component
               # assuming at this point that all Components are going to have descMetadata datastreams that is written
               # in MODS 3.4.
               content_models.push(Fedora_content_models['mods34'])
               if object.level == 'item'
                  content_models.push(Fedora_content_models['ead-item'])
               elsif object.level == 'guide'
                  content_models.push(Fedora_content_models['ead-collection'])
               else
                  content_models.push(Fedora_content_models['ead-component'])
               end
            elsif object.is_a? MasterFile
               if object.tech_meta_type == 'image'
                  content_models.push(Fedora_content_models['jp2k'])
               end
               if object.dpla
                  content_models.push(Fedora_content_models['dpla-item'])
               end
            else
               content_model = nil
            end
            if not content_models.empty?
               content_models.each do |content_model|
                  xml.__send__ "fedora-model".to_sym, :hasModel, "rdf:resource".to_sym => "info:fedora/#{content_model}"
               end
            end
         end
      end

      return output
   end

   #-----------------------------------------------------------------------------

   # Takes a Metadata Record, Component, or MasterFile record and returns a string
   # containing descriptive metadata, in the form of a MODS XML document. See
   # http://www.loc.gov/standards/mods/
   #
   # By default, all Units associated with the Metadata record are exported. Optionally
   # takes an array of Unit records which serves as a filter for the Units to
   # be exported; that is, a Unit must be included in the array passed to be
   # included in the export.
   #
   def self.desc(object, units_filter = nil)
      # If there is a Metadata record with Sirsi MARC XML available, that MARC XML will be transformed into
      # the MODS that will be ingested as the Hydra-compliant descMetadata
      if object.is_a? Metadata and object.type == "SirsiMetadata"
         sirsi_metadata = object.becomes(SirsiMetadata)
         doc = Nokogiri::XML( mods_from_marc(sirsi_metadata) )
         last_node = doc.xpath("//mods:mods/mods:location").last

         # Add node for indexing
         index_node = Nokogiri::XML::Node.new "identifier", doc
         index_node['type'] = 'uri'
         index_node['displayLabel'] = 'Accessible index record displayed in VIRGO'
         index_node['invalid'] = 'yes' unless object.discoverability
         index_node.content = "#{object.pid}"
         last_node.add_next_sibling(index_node)

         # Add node with Tracksys Metadata ID
         metadata_id_node = Nokogiri::XML::Node.new "identifier", doc
         metadata_id_node['type'] = 'local'
         metadata_id_node['displayLabel'] = 'Digital Production Group Tracksys Metadata ID'
         metadata_id_node.content = "#{object.id}"
         last_node.add_next_sibling(metadata_id_node)

         # Add nodes with Unit IDs that are included in DL
         object.units.each do |unit|
            if unit.include_in_dl == true
               unit_id_node = Nokogiri::XML::Node.new "identifier", doc
               unit_id_node['type'] = 'local'
               unit_id_node['displayLabel'] = 'Digital Production Group Tracksys Unit ID'
               unit_id_node.content = "#{unit.id}"
               last_node.add_next_sibling(unit_id_node)
            end
         end

         output = doc.to_xml
      else
         # Object is not sirsi metadata
         output = ''
         xml = Builder::XmlMarkup.new(:target => output, :indent => 2)
         xml.instruct! :xml  # Include XML declaration

         # If it is metadata, it must be XML metadata
         if object.is_a? Metadata
            mods_from_xml_metadata(xml, object, units_filter)
         else
            # Must be a master file
            xml.mods(:mods,
               "xmlns:mods".to_sym => Fedora_namespaces['mods'],
               "xmlns:xsi".to_sym => Fedora_namespaces['xsi'],
               "xsi:schemaLocation".to_sym => Fedora_namespaces['mods'] + ' ' + Schema_locations['mods']
            )
            mods_from_master_file(xml, object)
         end
      end
      return output
   end

   # Generate mods from sirsi metadata
   #
   def self.mods_from_marc(object)
      xslt_str = File.read("#{Rails.root}/lib/xslt/MARC21slim2MODS3-4.xsl")
      i0 = xslt_str.index "<xsl:include"
      i1 = xslt_str.index("\n", i0)
      inc = "<xsl:include href=\"#{Rails.root}/lib/xslt/MARC21slimUtils.xsl\"/>"
      fixed = "#{xslt_str[0...i0]}#{inc}#{xslt_str[i1+1...-1]}"
      xslt = Nokogiri::XSLT(fixed)

      # first try virgi as a source for marc as it has filterd out sensitive data
      # If not found, the response will just be: <?xml version="1.0"?> with no mods: info
      xml = Nokogiri::XML(open("http://search.lib.virginia.edu/catalog/#{object.catalog_key}.xml"))
      if xml.to_s.include?("mods:") == false
         # Not found, try solr index. If found, data is wrapped in a collection. Fix it
         xml_string = Virgo.get_marc(object.catalog_key)
         idx = xml_string.index("<record>")
         a = xml_string[idx..-1]
         idx = a.index("</collection>")
         b = a[0...idx]
         c = b.gsub(/<record>/, "<record xmlns=\"http:\/\/www.loc.gov\/MARC21\/slim\">")
         xml = Nokogiri::XML( c )
      end

      mods = xslt.transform(xml, ['barcode', "'#{object.barcode}'"])

      # In order to reformat and pretty print the MODS record after string insertion, the document is reopened and then
      # manipulated by Nokogiri.
      doc = Nokogiri.XML(mods.to_xml) do |config|
         config.default_xml.noblanks
      end
      return doc.to_xml
   end

   # Outputs descriptive metadata for a metadata record as a MODS document
   #
   def self.mods_from_xml_metadata(xml, metadata, units_filter)  ## TODO STOPPED
      # start <mods:mods> element
      xml.mods(:mods,
         "xmlns:mods".to_sym => Fedora_namespaces['mods'],
         "xmlns:xsi".to_sym => Fedora_namespaces['xsi'],
         "xsi:schemaLocation".to_sym => Fedora_namespaces['mods'] + ' ' + Schema_locations['mods']
      ) do

         # Put PID for object into MODS.  In order to transform this into a SOLR doc, there must be a PID in the MODS.
         xml.mods :identifier, metadata.pid, :type =>'pid', :displayLabel => 'UVA Library Fedora Repository PID'
         if metadata.discoverability
            xml.mods :identifier, metadata.pid, :type =>'uri', :displayLabel => 'Accessible index record displayed in VIRGO'
         else
            xml.mods :identifier, metadata.pid, :type =>'uri', :displayLabel => 'Accessible index record displayed in VIRGO', :invalid => 'yes'
         end

         # type of resource
         if metadata.is_manuscript? and metadata.is_collection?
            xml.mods :typeOfResource, metadata.resource_type, :manuscript => 'yes', :collection => 'yes'
         elsif metadata.is_manuscript?
            xml.mods :typeOfResource, metadata.resource_type, :manuscript => 'yes'
         elsif metadata.is_collection?
            xml.mods :typeOfResource, metadata.resource_type, :collection => 'yes'
         else
            xml.mods :typeOfResource, metadata.resource_type
         end

         # genre
         unless metadata.genre.blank?
            xml.mods :genre, metadata.genre, :authority => 'marcgt'
         end

         # title
         unless metadata.title.blank?
            xml.mods :titleInfo do
               xml.mods :title, metadata.title
            end
         end

         # creator
         unless metadata.creator_name.blank?
            xml.mods :name do
               xml.mods :namePart, metadata.creator_name
            end
         end

         mods_originInfo(xml, metadata, units_filter)
         mods_physicalDescription(xml, metadata, units_filter)
         mods_location(xml, metadata)
         mods_recordInfo(xml)
      end  # </mods:mods>
   end
   private_class_method :mods_from_xml_metadata

   #-----------------------------------------------------------------------------

   # Outputs a +mods:location+ element
   def self.mods_location(xml, metadata)
      xml.mods :location do
         if metadata.is_personal_item
            xml.mods :physicalLocation, '[personal copy]'
         else
            #xml.mods :physicalLocation, 'University of Virginia Library'
            xml.mods :physicalLocation, 'viu', :authority => 'marcorg'
         end

         xml.mods :url, @xml_file_name, :usage => 'primary display', :access => 'object in context'
      end
   end
   private_class_method :mods_location

   #-----------------------------------------------------------------------------

   # Outputs a MasterFile record as a +mods:relatedItem+ element
   def self.mods_from_master_file(xml, master_file, count = nil)

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
   private_class_method :mods_from_master_file

   #-----------------------------------------------------------------------------

   # Outputs a +mods:originInfo+ element
   def self.mods_originInfo(xml, metadata, units_filter)
      xml.mods :originInfo do
         # date captured (date of digitization)
         # Use the latest date_completed value from associated units
         date_completed = nil
         metadata.units.each do |unit|
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
   def self.mods_physicalDescription(xml, metadata, units_filter)
      xml.mods :physicalDescription do
         # Determine extent -- that is, number of files. First preference is to count
         # MasterFile records associated with this record; second is
         # unit_extent_actual value; last resort is unit_extent_estimated value.
         c = 0
         metadata.units.each do |unit|
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

         # NOTE: all masterfiles were hardcoded to image/tiff. The
         # code previously here to loop thru available types and add
         # multiples did nothing except this:
         xml.mods :internetMediaType, 'image/tiff'
      end
   end
   private_class_method :mods_physicalDescription

   #-----------------------------------------------------------------------------

   # Outputs a +mods:recordInfo+ element
   def self.mods_recordInfo(xml)
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
