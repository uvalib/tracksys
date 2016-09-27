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

      if !object.discoverability
         payload["shadowedItem"] = "HIDDEN"
      else
         payload["shadowedItem"] = "VISIBLE"
      end

      if object.is_a? Metadata
         # Hack to hide jefferson papers stuff (order 2575)
         if object.orders.where(id: 2575).count > 0
            payload["shadowedItem"] = "HIDDEN"
         end

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
         payload[k] = v.gsub(/'/,"") if !v.blank?
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
         last_node = doc.xpath("//mods:mods/mods:recordInfo").last

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

      # first try virgo as a source for marc as it has filterd out sensitive data
      # If not found, the response will just be: <?xml version="1.0"?> with no mods info
      xml = Nokogiri::XML(open("http://search.lib.virginia.edu/catalog/#{object.catalog_key}.xml"))
      if xml.to_s.include?("xmlns") == false
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
         # colon not allowed in ID. Replace with underscore
         relatedItem_id = master_file.pid.gsub(/:/, "_")
      end

      xml.mods :titleInfo do
         if master_file.title.blank?
            if count.nil?
               title = "[#{display_label}]"
            else
               title = "[#{display_label} #{count}]"
            end
            xml.mods :title, title
         else
            xml.mods :title, master_file.title
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
end
