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

   # Crosswalk Creator info from MODS to QDC
   #
   def self.crosswalk_creator(doc, metadata_type)
      out = []
      concat_names = []
      curr_name = {}
      if metadata_type == "SirsiMetadata"
         doc.xpath("/mods/name").each do |node|
            if QDC.get_attribute(node, "type") == "primary" ||
               QDC.get_attribute(node, "usage") == "primary" ||
               QDC.get_attribute(node, "nameTitleGroup") == "1"
               # PROCESS ONLY THIS NODEs nameParts
               name = ""
               node.xpath("namePart").each do |np|
                  name << ", " if name.length > 0
                  name << clean_xml_text(np.text)
               end
               val = node.attribute("valueURI")
               if val.blank?
                  out << "<dcterms:creator>#{name}</dcterms:creator>"
               else
                  out << "<dcterms:creator valueURI=\"#{val.value()}\">#{name}</dcterms:creator>"
               end
               break
            end
         end
         return out
      end

      doc.xpath("/mods/name/namePart").each do |node|
         value_uri = QDC.get_attribute(node.parent,"valueURI")
         if QDC.get_attribute(node, "type") == "family"
            if curr_name.has_key? :family
               concat_names << curr_name
               curr_name = {family: clean_xml_text(node.text), value_uri: value_uri }
            else
               curr_name[:family] = clean_xml_text(node.text)
            end
         elsif  QDC.get_attribute(node, "type") == "given"
            if curr_name.has_key? :given
               concat_names << curr_name
               curr_name = {given: clean_xml_text(node.text), value_uri: value_uri }
            else
               curr_name[:given] = clean_xml_text(node.text)
            end
         elsif QDC.get_attribute(node, "type") == "date"
            if curr_name.has_key? :date
               concat_names << curr_name
               curr_name = {date: clean_xml_text(node.text), value_uri: value_uri }
            else
               curr_name[:date] = clean_xml_text(node.text)
            end
         else
            if value_uri.blank?
               out << "<dcterms:creator>#{clean_xml_text(node.text)}</dcterms:creator>"
            else
               out << "<dcterms:creator valueURI=\"#{value_uri}\">#{clean_xml_text(node.text)}</dcterms:creator>"
            end
         end

         # a complete name has family, given and date.
         # if we have al 3 add it to the list of names
         if curr_name.keys.size >= 3
            concat_names << curr_name
            curr_name = {}
         end
      end

      if curr_name.keys.size > 0
         concat_names << curr_name
      end

      concat_names.each do |n|
         name = n[:family]
         if !n[:given].blank?
            name << ", #{n[:given]}"
         end
         if !n[:date].blank?
            name << ", #{n[:date]}"
         end
         if n[:value_uri].blank?
            out << "<dcterms:creator>#{name}</dcterms:creator>"
         else
            out << "<dcterms:creator valueURI=\"#{value_uri}\">#{name}</dcterms:creator>"
         end
      end

      return out
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
      hack = {"basketball": "http://id.loc.gov/vocabulary/graphicMaterials/tgm000841",
              "fraternities & sororities": "http://id.loc.gov/vocabulary/graphicMaterials/tgm004278"}
      doc.xpath(xpath).each do |n|
         # Per Jeremy, don't include language if objectPart is present
         next if  xpath.include?("languageTerm") && !n.attribute("objectPart").blank?

         txt = clean_xml_text(n.text)
         hack_val = hack[txt.downcase]
         if !hack_val.blank?
            out << "<#{qdc_ns}:#{qdc_ele} valueURI=\"#{hack_val}\">#{txt}</#{qdc_ns}:#{qdc_ele}>"
         else
            val = n.attribute("valueURI")
            if !val.nil? && (xpath.include?("genre") || xpath.include?("subject"))
               out << "<#{qdc_ns}:#{qdc_ele} valueURI=\"#{val.value()}\">#{txt}</#{qdc_ns}:#{qdc_ele}>"
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
      ignore_dates = ["undated", "unknown date", "unknown"]
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
            next if ignore_dates.include? node.text.strip.downcase
            next if node.text.strip.include?("?") || node.text.strip.include?("[") || node.text.strip.include?("]")

            if QDC.get_attribute(node, "encoding") == "marc"
               if QDC.get_attribute(node, "point") == "start"
                  dates[:start] = clean_xml_text(node.text)
               elsif QDC.get_attribute(node, "point") == "end"
                  dates[:end] = clean_xml_text(node.text)
               else
                  dates[:marc] = clean_xml_text(node.text)
               end
            else
               if dates[:general].nil?
                  dates[:general] = []
               end
               dates[:general] << clean_xml_text(node.text)
            end
         end

         if !dates[:start].blank? && !dates[:end].blank?
            out << "<dcterms:created>#{dates[:start]}/#{dates[:end]}</dcterms:created>"
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

   def self.crosswalk_subject_name(doc, metadata_type)
      out = []
      if metadata_type == "XmlMetadata"
         # return multiple, but join multiple nameParts with a comma
         # If valueURI is present, include it
         doc.xpath("/mods/subject/name").each do |node|
            ele_txt = ""
            val_uri = QDC.get_attribute(node, "valueURI")
            node.xpath("namePart").each do |np|
               ele_txt << ", " if ele_txt.length > 0
               ele_txt << clean_xml_text(np.text)
            end
            if val_uri.blank?
               out << "<dcterms:subject>#{ele_txt}</dcterms:subject>"
            else
               out << "<dcterms:subject valueURI=\"#{val_uri}\">#{ele_txt}/</dcterms:subject>"
            end
         end
         return out
      end

      # SIRSI: Only return a SINGE element, but join text, date and termsOfAddress with a comma
      curr = ""
      doc.xpath("/mods/subject/name/namePart").each do |n|
         txt = clean_xml_text(n.text)
         if n.attributes.count == 0
            if !curr.blank?
               out << "<dcterms:subject>#{curr}/</dcterms:subject>"
            end
            curr = txt
         elsif n.attribute("type") == "date" || n.attribute("type") == "termsOfAddress"
            curr << ", #{txt}"
         end
      end
      out << "<dcterms:subject>#{curr}</dcterms:subject>" if !curr.blank?
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

end
