module Virgo

# This module provides methods for updating Bibl records with metadata from an
# external source, namely the U.Va. Library catalog / Blacklight.

  require 'net/http'
  require 'logger'

  @log = Logger.new(STDOUT)

  @metadata_server = "#{SOLR_PRODUCTION_NAME}"

  # Queries the external metadata server for the catalog ID passed, and returns
  # a new Bibl object populated with values from that external record.
  #
  # Second parameter is a barcode value to be used for comparison against the
  # barcode from the external metadata record. For some fields, under certain
  # circumstances, such comparison is needed to disambiguate multiple MARC 999
  # (local use) fields.
  # 
  # UPDATE: Alternatively, this method can be called by passing nil for
  # catalog_key, in which case it queries the metadata server for the barcode
  # passed.
  # 
  # Does not save the Bibl record to the database; the Bibl object is just a
  # convenient carrier for the metadata values gleaned from the external record.
  #
  # Any error that occurs is raised to the calling method.

  def self.validate_barcode(barcode)
    Net::HTTP.start( @metadata_server) do |http|
      xml_doc = query_metadata_server(http, barcode, 'barcode_facet')
      begin
        doc = REXML::XPath.first(xml_doc, "/response/result/doc")
        raise if doc.nil?
        return true
      rescue
        # no catalog record found
        return false
      end
    end
  end

  def self.external_lookup(catalog_key, barcode)
    # normalize parameters
    catalog_key = catalog_key.strip.downcase unless catalog_key.blank?
    barcode = barcode.strip.upcase unless barcode.blank?
    if catalog_key.blank? and barcode.blank?
      raise ArgumentError, "BiblExternalUpdate#external_lookup: catalog_key and barcode are both blank; nothing to look up"
    end
    
    # instantiate a new Bibl object to populate with values and return
    bibl = Bibl.new
    bibl.date_external_update = Time.now
    
    # open HTTP session
    Net::HTTP.start( @metadata_server) do |http|
      # query the metadata server for this catalog ID or barcode
      if catalog_key.blank?
        # query for barcode
        xml_doc = query_metadata_server(http, barcode, 'barcode_facet')
      else
        # query for catalog ID
        xml_doc = query_metadata_server(http, catalog_key)
      end
      
      # from the server's response XML, get the <doc> element (which
      # contains everything we're interested in here)
      doc = get_main_element(xml_doc, catalog_key)
      
      # pull values from <doc> element and plug those values into Bibl object
      set_bibl_attributes(doc, bibl, barcode)
    end
    
    return bibl
  end

  # Updates Bibl records with metadata from an external source
  #
  # In:
  # * array of Bibl records to be updated
  # * computing ID of user (used to associate notifications about this batch
  #   process with this specific user)
  # Out: Returns nil. Notifications of warnings/errors are saved to database (as
  # ProcessNotificationRef records).
  def self.external_update(bibls, computing_id)
    # open HTTP session
    Net::HTTP.start( @metadata_server, @port ) do |http|
      bibls.each do |bibl|
        if bibl.catalog_key.blank?
          #add_notification(computing_id, bibl.id, 'missing_catalog_key')
          next
        end
        
        # query the metadata server for this catalog ID
        # Note: Any exception occurring here is likely to occur for all Bibl
        # objects; instead of saving a notification for each and every Bibl
        # object, let exceptions bubble up to calling method to be handled for
        # the whole process.
        xml_doc = query_metadata_server(http, bibl.catalog_key)
        
        # from the server's response XML, get the <doc> element (which
        # contains everything we're interested in here)
        begin
          doc = get_main_element(xml_doc, bibl.catalog_key)
        rescue
          # no catalog record found for that catalog ID
          # add_notification(computing_id, bibl.id, 'record_not_found')
          next
        end
        
        # pull values from <doc> element and plug those values into Bibl object
        set_bibl_attributes(doc, bibl, bibl.barcode)
        
        # save changes to Bibl record
        bibl.save
        # add_notification(computing_id, bibl.id, 'updated')
      end
    end
    
    return nil
  end


  #-----------------------------------------------------------------------------
  # private methods
  #-----------------------------------------------------------------------------

  # Reads the XML document (REXML::Document object) passed and gets the main XML
  # element needed for our purposes.
  def self.get_main_element(xml_doc, catalog_key)
    # when querying solrpowr.lib, the main element is /response/result/doc
    begin
      doc = REXML::XPath.first(xml_doc, "/response/result/doc")
      raise if doc.nil?
    rescue
      # no catalog record found
      raise "No corresponding record was found in the Library catalog"
    end
    return doc
  end
  private_class_method :get_main_element

  #-----------------------------------------------------------------------------

  # Queries the metadata server using the HTTP session passed and the ID of the
  # metadata record to look up. Returns REXML::Document object containing the
  # server's response.
  def self.query_metadata_server(http, query_value, query_field='id')
    # query Solr server to get XML results for this catalog ID
    xml_string = http.get( "/virgobeta/select/?q=#{query_field}:#{query_value}" ).body
    # read XML string into REXML document object
    begin
      xml_doc = REXML::Document.new(xml_string)
    rescue
      raise "The metadata server did not return an XML response"
    end
    return xml_doc
  end
  private_class_method :query_metadata_server

  #-----------------------------------------------------------------------------

  # Pulls values from the XML element (REXML::Element object) passed and plugs
  # those values into the corresponding attributes of the Bibl object passed.
  #
  # Third parameter is a barcode value to be used for comparison against the
  # barcode from the external metadata record. For some fields, such comparison
  # is needed to disambiguate multiple MARC 999 (local use) fields.
  def self.set_bibl_attributes(doc, bibl, compare_barcode)
    if compare_barcode.nil?
      compare_barcode = ''
    else
      compare_barcode = compare_barcode.strip.upcase  # normalize for comparison
    end
    
    # catalog ID
    el = REXML::XPath.first(doc, "arr[@name='id']/str")
    bibl.catalog_key = el.text unless el.nil?
    
    # title
    el = REXML::XPath.first(doc, "arr[@name='title_display']/str")
    bibl.title = el.text unless el.nil?
    
    # creator name
    el = REXML::XPath.first(doc, "arr[@name='author_display']/str")
    bibl.creator_name = el.text unless el.nil?
    
    # Get MARC XML record (embedded in Blacklight response in <arr name="marc_display">)
    marc_record = nil
    el = REXML::XPath.first(doc, "str[@name='marc_display']")
    marc_string = el.text unless el.nil?
    begin
      marc_xml = REXML::Document.new(marc_string)
      marc_record = REXML::XPath.first(marc_xml, "/collection/record")
    rescue
      # No need to alert user that not all possible fields could be updated;
      # we're highlighting the fields that actually get updated (see
      # BiblController#external_lookup)
    end
    
    if marc_record
      # title
      #
      # Get subtitle in addition to main title (replacing title value from
      # Blacklight title_display field (see above) which typically only includes
      # main title)
      marc245 = REXML::XPath.first(marc_record, "datafield[@tag='245']")
      if marc245
        marc245a = REXML::XPath.first(marc245, "subfield[@code='a']")
        if marc245a and marc245a.text
          # only replace Blacklight title_display value if MARC 245$b is present
          marc245b = REXML::XPath.first(marc245, "subfield[@code='b']")
          if marc245b and marc245b.text
            title_a = marc245a.text.strip
            title_b = marc245b.text.strip.sub(/\s*\/$/,'')  # remove trailing / character
            bibl.title = "#{title_a} #{title_b}"
          end
        end
      end
      
      # creator name type (personal or corporate)
      marc100 = REXML::XPath.first(marc_record, "datafield[@tag='100']")
      marc110 = REXML::XPath.first(marc_record, "datafield[@tag='110']")
      marc111 = REXML::XPath.first(marc_record, "datafield[@tag='111']")
      if marc100
        bibl.creator_name_type = 'personal'
      elsif marc110 or marc111
        bibl.creator_name_type = 'corporate'
      else
        bibl.creator_name_type = nil
      end
      
      # title control number
      #
      # MARC 035 is repeatable; we want the Sirsi control number
      #
      # <datafield tag="035" ind1=" " ind2=" ">
      #   <subfield code="a">(Sirsi) o17551904</subfield>
      # </datafield>
      # <datafield tag="035" ind1=" " ind2=" ">
      #   <subfield code="a">(OCoLC)17551904</subfield>
      # </datafield>
      REXML::XPath.each(marc_record, "datafield[@tag='035']/subfield[@code='a']") do |marc035a|
        if marc035a.text
          matchdata = marc035a.text.match(/^\(Sirsi\)/)
          if matchdata
            title_control = matchdata.post_match.strip
            bibl.title_control = title_control unless title_control.blank?
          end
        end
      end
      
      # year
      #
      # Get date of publication from MARC 260$c. Both field 260 and subfield c
      # are repeatable; just grab first one.
      marc260c = REXML::XPath.first(marc_record, "datafield[@tag='260']/subfield[@code='c']")
      if marc260c and marc260c.text
        bibl.year = marc260c.text.strip.sub(/^\[/,'').sub(/\]$/,'').sub(/\.$/,'')
        bibl.year_type = 'publication'
      end

      # Note: For call number, we don't want MARC 050, which is the LC call
      # number; we want the local/UVa call number, which is in 999$a.
      
      # Get call number, copy, and location from MARC 999 (local use) field
      #
      # <datafield tag='999' ind1=' ' ind2=' '>
      #   <subfield code='a'>DA155 .W48 2008</subfield>
      #   <subfield code="c">1</subfield>
      #   <subfield code='i'>X030468328</subfield>
      #   <subfield code="l">FA-STKS</subfield>
      #   ...
      # </datafield>

      # MARC 524a - Special Collections Staff often put a canonical citation in
      # this field.  If present in the marcxml file, pull and store in bibl record.
      marc524a = REXML::XPath.first(marc_record, "datafield[@tag='524']/subfield[@code='a']")
      if marc524a and marc524a.text
        bibl.citation = marc524a.text
      end

      # MARC 999 is repeatable -- normally one for each barcode. Build a hash of
      # barcode values from 999 fields, where key is barcode and value is
      # another hash with "call_number", "copy", and "location" entries.
      barcodes = Hash.new
      REXML::XPath.each(marc_record, "datafield[@tag='999']") do |marc999|
        # get barcode from subfield "i"
        marc999i = REXML::XPath.first(marc999, "subfield[@code='i']")
        if marc999i and marc999i.text
          barcode = marc999i.text.strip.upcase
          barcodes[barcode] = Hash.new
        else
          barcode = ''
        end
        
        # Get local call number from subfield "a"
        marc999a = REXML::XPath.first(marc999, "subfield[@code='a']")
        if marc999a and marc999a.text
          barcodes[barcode]['call_number'] = marc999a.text.strip unless barcode.blank?
        end
        
        # Get copy from subfield "c"
        marc999c = REXML::XPath.first(marc999, "subfield[@code='c']")
        if marc999c and marc999c.text
          barcodes[barcode]['copy'] = marc999c.text.strip unless barcode.blank?
        end
        
        # Get location from subfield "l"
        marc999l = REXML::XPath.first(marc999, "subfield[@code='l']")
        if marc999l and marc999l.text
          barcodes[barcode]['location'] = marc999l.text.strip unless barcode.blank?
        end
      end
      
      # If barcode passed matches a barcode found in a MARC 999 field, then set
      # the call number, copy, and location associated with that barcode
      if barcodes.has_key? compare_barcode
        bibl.barcode = compare_barcode
        bibl.call_number = barcodes[compare_barcode]['call_number']
        bibl.copy = barcodes[compare_barcode]['copy']
        bibl.location = barcodes[compare_barcode]['location']
      else
        # if there is exactly one 999 field, use it
        if barcodes.length == 1
          barcode = barcodes.keys.first
          bibl.barcode = barcode
          bibl.call_number = barcodes[barcode]['call_number']
          bibl.copy = barcodes[barcode]['copy']
          bibl.location = barcodes[barcode]['location']
        end
      end
    end  # END if marc_record
    
    # record date/time this Bibl record was updated from external source
    bibl.date_external_update = Time.now
  end
  private_class_method :set_bibl_attributes

end
