module Virgo

# This module provides methods to retrieve metadata from an
# external source, namely the U.Va. Library catalog / Blacklight.

  require 'rest_client'
  require 'nokogiri'

  def self.roman_mapping
     {
        1000 => "M",
        900 => "CM",
        500 => "D",
        400 => "CD",
        100 => "C",
        90 => "XC",
        50 => "L",
        40 => "XL",
        10 => "X",
        9 => "IX",
        5 => "V",
        4 => "IV",
        1 => "I"
     }
  end

  def self.to_arabic(str, result = 0)
     return result if str.empty?
     roman_mapping.values.each do |roman|
        if str.start_with?(roman)
           result += roman_mapping.invert[roman]
           str = str.slice(roman.length, str.length)
           return to_arabic(str, result)
        end
     end
  end

  def self.get_marc_publication_info(catalog_key, barcode)
     xml_doc = nil
     blank = {year: "", place: ""}

     catalog_key = catalog_key.strip.downcase unless catalog_key.blank?
     barcode = barcode.strip.upcase unless barcode.blank?
     if catalog_key.blank? and barcode.blank?
       raise "catalog_key and barcode are both blank"
     end

     begin
        if catalog_key.blank?
         xml_doc = query_metadata_server(barcode, 'barcode_facet')
       else
         xml_doc = query_metadata_server(catalog_key)
       end
     rescue Exception=>e
        # failed request. nothing to do, blank will be returned below
     end
     return blank if xml_doc.blank?

     doc = xml_doc.xpath("/response/result/doc").first
     return blank if doc.blank?
     marc_ele = doc.xpath("str[@name='marc_display']").first
     return blank if marc_ele.nil?

     marc_string = marc_ele.text
     marc_xml = Nokogiri::XML(marc_string)
     marc_xml.remove_namespaces!
     marc_record = marc_xml.xpath("/collection/record").first
     return blank if marc_record.nil?

     year = ""
     marc260c = marc_record.xpath("datafield[@tag='260']/subfield[@code='c']").first
     if !marc260c.nil?
        year = extract_year_from_raw_260c(marc260c.text)
     end

     place = ""
     foo= marc_record.xpath("datafield[@tag='260']")
     marc044c = marc_record.xpath("datafield[@tag='260']/subfield[@code='a']").first
     if !marc044c.nil?
        place = marc044c.text
        if place.match(/.*:\s*\z/)  # end with a colon
           place = place[0...place.rindex(":")].strip
        end
        if place.match(/.*,\s*\z/)  # end with a comma
           place = place[0...place.rindex(",")].strip
        end
        if !place.match(/[\[].*[\]]/) # just open bracket
           place.gsub! /\[/, ''
        end
        if place.match(/\A[\[].*[\]]\z/) # start and end with []
           place.gsub!(/(\[|\])/, '')
        end
     end
     return { year: year, place: place}
  end

  def self.extract_year_from_raw_260c(year)
     return "" if year.blank?
     year = year.strip.gsub(/([\[\]\(\)]|\.\z)/, '')
     return "" if year.blank?

     begin
        # convert to date obj, then to year-only string.
        # make sure the resultant year is contained in the original string
        test = year.to_date.strftime("%Y")
        raise "Invalid" if year.index(test).nil?
        year = test
     rescue Exception=>e
        # if rails cant parse, it will raise an exception
        # next, look for stuff like 1871.0
        if !year.match(/^\d{4}.0/).nil?
           year = year.split(".")[0]
        else
           if !year.match(/^\d{2}--/).nil?
             # only century know
             year = "#{year[0...2]}99"
          elsif !year.match(/^\d{3}-/).nil?
             # only decade known
             year = "#{year[0...3]}9"
          elsif !year.match(/^\d{4}\s*-\s*\d{4}/).nil?
             # range of years separated by dash
             year = year.split("-")[1].strip
          elsif !year.match(/^\d{4}\s*-\s*\d{2}/).nil?
             # range of years separated by dash; only 2 digits listed after dash
             bits = year.split("-")
             year = "#{bits[0].strip[0...2]}#{bits[1].strip}"
          else
             # mess. just strip out non-number/non-space and see if anything looks like a year
             year = year.gsub(/\s+/, ' ')
             stripped_year = year.gsub(/[^0-9 ]/i, '')
             latest = 0
             stripped_year.split(" ").each do |bit|
                bit.strip!
                if bit.length == 4
                   latest = bit.to_i if bit.to_i > latest
                end
             end
             if latest > 0
                year = latest.to_s
             else
                # Still nothing... see if anything looks like roman numeral year
                year = year.gsub(/[^IVXLCDM ]/, '')
                year.split(" ").each do |bit|
                   val = to_arabic(bit)
                   latest = val if val >= 1500 and val > latest
                end
                year = ""
                year = latest.to_s if latest > 0
             end
          end
       end
     end
     return year.split(" ")[0] if !year.blank? # in case there is junk after last year
  end

  # Queries the external metadata server for the catalog ID passed, and returns
  # a new metadata object populated with values from that external record.
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
  # Any error that occurs is raised to the calling method.

  def self.external_lookup(catalog_key, barcode)
    # normalize parameters
    catalog_key = catalog_key.strip.downcase unless catalog_key.blank?
    barcode = barcode.strip.upcase unless barcode.blank?
    if catalog_key.blank? and barcode.blank?
      raise ArgumentError, "Catalog_key and barcode are both blank; nothing to look up"
    end

    # query Solr index
    begin
      # query the metadata server for this catalog ID or barcode
      if catalog_key.blank?
        # query for barcode
        xml_doc = query_metadata_server( barcode, 'barcode_facet')
      else
        # query for catalog ID
        xml_doc = query_metadata_server(catalog_key)
      end

      # from the server's response XML, get the <doc> element (which
      # contains everything we're interested in here)
      doc = get_main_element(xml_doc, catalog_key)

      # pull values from <doc> element and plug those values into a metadata hash
      return get_metadata_json(doc, barcode)
    rescue
      raise "Query to #{Settings.solr_url} with key #{catalog_key} and barcode #{barcode} failed to return a valid result."
    end
  end

  def self.get_marc(catalog_key)
     xml_doc = query_metadata_server(catalog_key)
     doc = xml_doc.xpath(xml_doc, "/response/result/doc").first
     el = doc.xpath( "str[@name='marc_display']" ).first
     return Nokogiri::XML(el.text).to_xml
  end

  def self.get_marc_doc(catalog_key)
     xml_doc = query_metadata_server(catalog_key)
     doc = xml_doc.xpath(xml_doc, "/response/result/doc").first
     el = doc.xpath( "str[@name='marc_display']" ).first
     return Nokogiri::XML(el.text)
  end


  #-----------------------------------------------------------------------------
  # private methods
  #-----------------------------------------------------------------------------

  # Reads the XML document (Nokogiri::XML::Document object) passed and gets the main XML
  # element needed for our purposes.
  def self.get_main_element(xml_doc, catalog_key)
    begin
      doc = xml_doc.xpath(xml_doc, "/response/result/doc").first
      raise if doc.nil?
    rescue
      # no catalog record found
      raise "No corresponding record was found in the Library catalog"
    end
    return doc
  end
  private_class_method :get_main_element

  #-----------------------------------------------------------------------------

  # Queries the metadata server using the hostname passed and the ID of the
  # metadata record to look up. Returns Nokogiri::XML::Document object containing the
  # server's response.
  def self.query_metadata_server(query_value, query_field='id')
    # query Solr server to get XML results for this catalog ID
    xml_string = RestClient.get( "#{Settings.solr_url}/core/select/?q=#{query_field}:#{query_value}" )
    # read XML string into Nokogiri::XML::Document object
    begin
      xml_doc = Nokogiri::XML(xml_string)
    rescue
      raise "The metadata server did not return an XML response"
    end
    return xml_doc
  end
  private_class_method :query_metadata_server

  #-----------------------------------------------------------------------------

  # MARC 999 is repeatable -- normally one for each barcode. Build a hash of
  # barcode values from 999 fields, where key is barcode and value is
  # another hash with "call_number", "copy", and "location" entries.
  def self.build_barcode_hash(marcxml)
    barcodes=Hash.new
    marc_record=marcxml
    raise ArgumentError, "argument not an XML element!" unless marc_record.is_a?(Nokogiri::XML::Element)
    marc_record.xpath("datafield[@tag='999']").each do |marc999|
      # get barcode from subfield "i"
      marc999i = marc999.xpath("subfield[@code='i']").first
      if marc999i and marc999i.text
        barcode = marc999i.text.strip.upcase
        barcodes[barcode] = Hash.new
      else
        barcode = ''
      end

      # Get local call number from subfield "a"
      marc999a = marc999.xpath("subfield[@code='a']").first
      if marc999a and marc999a.text
        barcodes[barcode]['call_number'] = marc999a.text.strip unless barcode.blank?
      end

      # Get copy from subfield "c"
      marc999c = marc999.xpath("subfield[@code='c']").first
      if marc999c and marc999c.text
        barcodes[barcode]['copy'] = marc999c.text.strip unless barcode.blank?
      end

      # Get location from subfield "l"
      marc999l = marc999.xpath("subfield[@code='l']").first
      if marc999l and marc999l.text
        barcodes[barcode]['location'] = marc999l.text.strip unless barcode.blank?
      end
    end
    barcodes
  end
  # private_class_method :build_barcode_hash

  #-----------------------------------------------------------------------------

  # Pulls values from the XML element (Nokogiri::XML::Element object) passed and plugs
  # those values into the corresponding attributes of the metadata object passed.
  #
  # Third parameter is a barcode value to be used for comparison against the
  # barcode from the external metadata record. For some fields, such comparison
  # is needed to disambiguate multiple MARC 999 (local use) fields.
  def self.get_metadata_json(doc, compare_barcode)
    if compare_barcode.nil?
      compare_barcode = ''
    else
      compare_barcode = compare_barcode.strip.upcase  # normalize for comparison
    end
    metadata = {}

    # title
    el = doc.xpath("arr[@name='title_display']/str").first
    metadata[:title] = el.text unless el.nil?

    # creator name
    el = doc.xpath("arr[@name='author_display']/str").first
    metadata[:creator_name] = el.text unless el.nil?

    # Get MARC XML record (embedded in Blacklight response in <arr name="marc_display">)
    marc_record = nil
    el = doc.xpath("str[@name='marc_display']").first
    marc_string = el.text unless el.nil?
    begin
      marc_xml = Nokogiri::XML(marc_string)
      marc_xml.remove_namespaces!
      marc_record = marc_xml.xpath("/collection/record").first
    rescue
    end

    if marc_record
      # catalog key
      cf = marc_record.xpath("controlfield[@tag='001']").first
      if !cf.blank?
         metadata[:catalog_key] = cf.text
      end

      # title
      #
      # Get subtitle in addition to main title (replacing title value from
      # Blacklight title_display field (see above) which typically only includes
      # main title)
      marc245 = marc_record.xpath("datafield[@tag='245']").first
      if marc245
        marc245a = marc245.xpath("subfield[@code='a']").first
        if marc245a and marc245a.text
          # only replace Blacklight title_display value if MARC 245$b is present
          marc245b = marc245.xpath("subfield[@code='b']").first
          if marc245b and marc245b.text
            title_a = marc245a.text.strip
            title_b = marc245b.text.strip.sub(/\s*\/$/,'')  # remove trailing / character
            metadata[:title] = "#{title_a} #{title_b}"
          end
        end
      end

      # creator name type (personal or corporate)
      marc100 = marc_record.xpath("datafield[@tag='100']").first
      marc110 = marc_record.xpath("datafield[@tag='110']").first
      marc111 = marc_record.xpath("datafield[@tag='111']").first
      if marc100
        metadata[:creator_name_type] = 'personal'
      elsif marc110 or marc111
        metadata[:creator_name_type] = 'corporate'
      end

      # title control number
      # 035 a
      marc035a = marc_record.xpath("datafield[@tag='035']/subfield[@code='a']").first
      if marc035a and marc035a.text
        matchdata = marc035a.text.match(/^\(Sirsi\)/)
        if matchdata
           title_control = matchdata.post_match.strip
           metadata[:title_control] = title_control unless title_control.blank?
        end
     end

      # year
      #
      # Get date of publication from MARC 260$c. Both field 260 and subfield c
      # are repeatable; just grab first one.
      marc260c = marc_record.xpath("datafield[@tag='260']/subfield[@code='c']").first
      if marc260c and marc260c.text
        metadata[:year] = marc260c.text.strip.sub(/^\[/,'').sub(/\]$/,'').sub(/\.$/,'')
        metadata[:year_type] = 'publication'
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
      # this field.  If present in the marcxml file, pull and store in metadata record.
      marc524a = marc_record.xpath("datafield[@tag='524']/subfield[@code='a']").first
      if marc524a and marc524a.text
        metadata[:citation] = marc524a.text
      end

      # MARC 040a - Cataloging Source.  In order to certify that our records are CC0 for
      # submission to DPLA, we need to record where the MARC record was authored.
      # VA@ is the code for the University of Virgina
      marc040a = marc_record.xpath("datafield[@tag='040']/subfield[@code='a']").first
      if marc040a and marc040a.text
        metadata[:cataloging_source] = marc040a.text
      end

      # MARC 999 is repeatable -- normally one for each barcode. Build a hash of
      # barcode values from 999 fields, where key is barcode and value is
      # another hash with "call_number", "copy", and "location" entries.
      barcodes = Hash.new
      barcodes = build_barcode_hash(marc_record)

      # If barcode passed matches a barcode found in a MARC 999 field, then set
      # the call number, copy, and location associated with that barcode
      metadata[:barcode] = compare_barcode # Default to whatever was requested
      if barcodes.has_key? compare_barcode
        metadata[:barcode] = compare_barcode
        metadata[:call_number] = barcodes[compare_barcode]['call_number']
        metadata[:copy] = barcodes[compare_barcode]['copy']
        metadata[:location] = barcodes[compare_barcode]['location']
      else
        # if there is exactly one 999 field, use it
        if barcodes.length == 1
          barcode = barcodes.keys.first
          metadata[:barcode] = barcode
          metadata[:call_number] = barcodes[barcode]['call_number']
          metadata[:copy] = barcodes[barcode]['copy']
          metadata[:location] = barcodes[barcode]['location']
        end
      end

      # See if there is any collection ID info.
      # This field should be automatically generated using the 852c field from the marc record,
      # or failing that, should fall back to presenting the value selected for the "call number" field.
      marc852c = marc_record.xpath("datafield[@tag='852']/subfield[@code='c']").first
      if marc852c && marc852c.text
         metadata[:collection_id] = marc852c.text
      else
         metadata[:collection_id] = metadata[:call_number]
      end
    end  # END if marc_record

    return metadata
  end
  private_class_method :get_metadata_json

end
