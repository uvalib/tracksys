module QDC
   # To avoid a single directory with tens of thousands of files, break
   # up the PID into 2 digit sub directories.
   #
   def self.relative_pid_path( pid )
      pid_parts = pid.split(":")
      base = pid_parts[1]
      parts = base.scan(/../) # break up into 2 digit sections, but this can leave off last digit
      parts << base.last if parts.length * 2 !=  base.length  # get last digit if necessary
      pid_dirs = parts.join("/")
      return File.join(pid_parts[0], pid_dirs)
   end

   # Do a crosswalk from MODS to QDC that can return a single QDC element.
   # Some MODS elements may have valueURI. If present, include it as an attribute.
   # These elements are: Name/namePart, sub-elements of hierarchicalGeographic,
   #                     subject/topic and subject/name
   def self.crosswalk(doc, xpath, qdc_ele)

      # first, check if this xpath is one of those that should check for valueURI
      include_value = false
      ["namePart", "hierarchicalGeographic", "subject/name"].each do |k|
         if xpath.include?(k)
            include_value = true
            break
         end
      end

      n = doc.at_xpath(xpath)
      if !n.nil?
         txt = clean_xml_text(n.text)
         return nil if txt.blank?
         txt = "Image" if txt == "still image"
         txt = "Text" if txt == "text"
         txt = "Physical Object" if txt == "three dimensional object"
         val = n.attribute("valueURI")
         if !val.blank? && include_value
            return "<dcterms:#{qdc_ele} valueURI=\"#{val.value()}\">#{txt}</dcterms:#{qdc_ele}>"
         end

         return "<dcterms:#{qdc_ele}>#{txt}</dcterms:#{qdc_ele}>"
      end
      return nil
   end

   # Do a crosswalk from MODS to QDC that can return multiple QDC elements.
   # Some MODS elements may have valueURI. If present, include it as an attribute.
   # For Multi, the only element that may have this is genre.
   #
   def self.crosswalk_multi(doc, xpath, qdc_ns, qdc_ele)
      out = []
      doc.xpath(xpath).each do |n|
         txt = clean_xml_text(n.text)
         value_uri = get_attribute(n, "valueURI")

         # Per Jeremy, special language handling: don't include language if objectPart is present
         # and don't include labguages with language term="zxx"
         next if  xpath.include?("languageTerm") && !n.attribute("objectPart").blank?
         next if  xpath.include?("languageTerm") && txt == "zxx"

         # For genre, lookup value in the values list from jeremy, If it matches
         # use it and include the valueURI. If not, map the value to dcterms:medium
         if xpath.include?("genre")
            value_uri = lookup_genre(txt)
            txt = txt.gsub(/\.$/, "")  # remove trailing . at end of genre
            if value_uri.blank?
               out << "<dcterms:medium>#{txt}</dcterms:medium>"
            else
               out << "<#{qdc_ns}:#{qdc_ele} valueURI=\"#{value_uri}\">#{txt}</#{qdc_ns}:#{qdc_ele}>"
            end
         else
            if !value_uri.nil? && xpath.include?("subject")
               out << "<#{qdc_ns}:#{qdc_ele} valueURI=\"#{value_uri}\">#{txt}</#{qdc_ns}:#{qdc_ele}>"
            else
              out << "<#{qdc_ns}:#{qdc_ele}>#{txt}</#{qdc_ns}:#{qdc_ele}>"
            end
         end
      end
      return out
   end

   # Crosswalk data in MODS /mods/originInfo/dateIssued and /mods/originInfo/dateCreated
   # to QDC dcterms:created.
   #
   def self.crosswalk_date_created(doc, metadata_type)
      ignore_dates = ["undated", "unknown date", "unknown", "n.d."]
      out = []

      if metadata_type == "SirsiMetadata"
         # Per Jeremy for SIRSI sources, just return dateCreated and dateIssued
         # Further: If dateIssued with encoding="marc" or dateCreated with encoding="marc" is
         #          present, select that value. Account for  point="start" and point="end" attributes too
         dates = {}
         nodes1 = doc.xpath("/mods/originInfo/dateCreated")
         nodes2 = doc.xpath("/mods/originInfo/dateIssued")
         nodes = nodes1+nodes2
         nodes.each do |node|
            clean_txt = clean_xml_text(node.text)
            next if ignore_dates.include? clean_txt.downcase
            next if clean_txt.include?("?") || clean_txt.include?("[") || clean_txt.include?("]")
            next if clean_txt == "uuuu"

            # handle merged create/copyright
            merged = clean_txt.split(",")
            if merged.size == 2
               clean_txt = merged[0]
               next if /[\d]{4}/.match(clean_txt).nil?
            elsif clean_txt.length == 8
               next if /[\d]{8}/.match(clean_txt).nil?
               clean_txt = clean_txt[0...4] # just take the first 4 chars
            end

            if QDC.get_attribute(node, "encoding") == "marc"
               if QDC.get_attribute(node, "point") == "start"
                  dates[:start] = clean_txt
               elsif QDC.get_attribute(node, "point") == "end"
                  dates[:end] = clean_txt
               else
                  dates[:marc] = clean_txt
               end
            else
               if dates[:general].nil?
                  dates[:general] = []
               end
               dates[:general] << clean_txt
            end
         end

         if !dates[:start].blank?
            if !dates[:end].blank?
               out << "<dcterms:created>#{dates[:start]}/#{dates[:end]}</dcterms:created>"
            else
               out << "<dcterms:created>#{dates[:start]}</dcterms:created>"
            end
         elsif !dates[:marc].blank?
            out << "<dcterms:created>#{dates[:marc]}</dcterms:created>"
         elsif !dates[:general].nil?
            dates[:general].each do |date|
               out << "<dcterms:created>#{date}</dcterms:created>"
            end
         end

         return out
      elsif metadata_type == "XmlMetadata"
         dates = []
         start_date = end_date = key_date = ""
         # Notes from Jeremy for XML sources:
         #   if there are multiple dateCreated and attributes point="start"
         #   and point="end", map both to a single date like start/end. If not, use the
         #   one with attribute keyDate="yes"
         doc.xpath("/mods/originInfo/dateCreated").each do |n|
            next if ignore_dates.include? n.text.strip.downcase

            # hold on to specific dates. decide which to use later
            if QDC.get_attribute(n, "keyDate") == "yes"
               key_date = clean_xml_text(n.text)
            end
            if QDC.get_attribute(n, "point")  == "start"
               start_date = clean_xml_text(n.text)
            end
            if QDC.get_attribute(n, "point")  == "end"
               end_date = clean_xml_text(n.text)
            end

            # track all dates found
            dates << clean_xml_text(n.text)
         end
      end

      if !start_date.blank? && !end_date.blank?
         out << "<dcterms:created>#{start_date}/#{end_date}</dcterms:created>"
      elsif !key_date.blank?
         out << "<dcterms:created>#{key_date}</dcterms:created>"
      else
         dates.each { |d| out << "<dcterms:created>#{d}</dcterms:created>" }
      end

      return out
   end

   # Crosswalk <subject><topic>, <subject><geographic>,<subject><temporal>, <subject><genre> into a single string
   # with each value listed in order encountered and separated by --.
   # There may be multiple subject elements. Each one gets its own delimited string
   # NOTE: a good test item is uva-lib:612592 (ID 1001)
   #
   def self.crosswalk_subject(doc)
      out = []
      targets = ["topic", "geographic", "temporal", "genre"]
      doc.xpath("/mods/subject").each do |subject|
         values = []
         val_uri = QDC.get_attribute(subject, "valueURI")
         subject.children.each do |child|
            next if targets.include?(child.name) == false
            values << clean_xml_text(child.text)
         end

         next if values.blank?

         # Per Jeremy, subjects with multiple values are 'compound subjects' and
         # do not have valueURI attributes. Single value subjects can
         if val_uri.blank? || values.length > 1
            out << "<dcterms:subject>#{values.join('--')}</dcterms:subject>"
         else
            out << "<dcterms:subject valueURI=\"#{val_uri}\">#{values.first}/</dcterms:subject>"
         end
      end
      return out
   end

   # Names are parsed from two different xpaths; /mods/name for creatorName
   # and /mods/subject/name for subject names
   def self.crosswalk_name(doc, xpath, qdc_ns, qdc_ele)
      out = []
      doc.xpath(xpath).each do |name_node|
         # only accept names with attribute type="personal"
         next if QDC.get_attribute(name_node, "type") != "personal"

         # NOTE: per ruby spec https://ruby-doc.org/core-2.5.1/Hash.html
         # the order of this hash will be preserved when values are iterated below to build the name
         parts = {"none"=>nil, "family"=>nil, "given"=>nil, "termsOfAddress"=>nil, "date"=>nil}
         val_uri = QDC.get_attribute(name_node, "valueURI")
         name_node.xpath("namePart").each do |np|
            if np.attributes.blank?
               parts["none"] = clean_xml_text(np.text)
            else
               part_type = QDC.get_attribute(np, "type")
               parts[part_type] = clean_xml_text(np.text)
            end
         end

         name_val = ""
         parts.values.each do |p|
            next if p.blank?
            name_val << ", " if !name_val.blank?
            name_val << p
         end

         if val_uri.blank?
            out << "<#{qdc_ns}:#{qdc_ele}>#{name_val}</#{qdc_ns}:#{qdc_ele}>"
         else
            out << "<#{qdc_ns}:#{qdc_ele} valueURI=\"#{val_uri}\">#{name_val}</#{qdc_ns}:#{qdc_ele}>"
         end
      end
      return out
   end

   # Crosswalk typeOfResource to QDC
   #
   def self.crosswalk_type_of_resource( doc )
      out = []
      csv_text = File.read(Rails.root.join('data', "qdc_crosswalk",  "type_of_resource.csv"))
      lookup = CSV.parse(csv_text, headers: false, col_sep: "|")
      doc.xpath("/mods/typeOfResource").each do |tor|
         text = QDC.clean_xml_text(tor.text)
         lookup.each do |row|
            if row[0] == text.downcase
               out << "<dcterms:type>#{row[1]}</dcterms:type>"
               break
            end
         end
      end
      return out
   end

   # Convert illegal XML characters to safe. These are: &, < and >
   #
   def self.clean_xml_text(val)
      clean = val.strip
      clean = clean.gsub(/&/, "&amp;").gsub(/</,"&lt;").gsub(/>/,"&gt;")
      return clean
   end

   def self.get_attribute(node, name)
      return nil if node.attribute(name).nil?
      return node.attribute(name).value()
   end

   def self.lookup_genre(genre)
      csv_text = File.read(Rails.root.join('data', "qdc_crosswalk",  "qdc_genres.csv"))
      CSV.parse(csv_text, headers: false).each do |row|
         if row[0] == genre.downcase
            return row[1]
         end
      end
      return nil
   end

   def self.is_visual_history?(doc, meta)
      # 3009 is the visual history collection...
      return true if meta.parent_metadata_id == 3009

      # ... but items may not always be attached to it. See if
      # <relatedItem type="series" displayLabel="Part of"><titleInfo><title>
      # is: "University of Virginia Visual History Collection"
      doc.xpath("/mods/relatedItem[@type='series'][@displayLabel='Part of']/titleInfo/title").each do |t|
         return true if QDC.clean_xml_text(t.text) == "University of Virginia Visual History Collection"
      end
      return false
   end

   def self.visual_history_rights(doc)
      ok_item = [
         { xpath: "/mods/name/namePart", name: "Skinner, David M", right_uri: "http://rightsstatements.org/vocab/CNE/1.0/"},
         { xpath: "/mods/name/namePart", name: "Thompson, Ralph R", right_uri: "http://rightsstatements.org/vocab/CNE/1.0/"},
         { xpath: "/mods/name/namePart", name: "Holsinger's Studio", right_uri: "http://rightsstatements.org/vocab/UND/1.0/"},
         { xpath: "/mods/subject/name/namePart", name: "University of Virginia. News Office", right_uri: "http://rightsstatements.org/vocab/CNE/1.0/"}
      ]

      ok_item.each do |i|
         doc.xpath(i[:xpath]).each do |name|
            if QDC.clean_xml_text(name.text).include? i[:name]
               return i[:right_uri]
            end
         end
      end

      return nil
   end

end
