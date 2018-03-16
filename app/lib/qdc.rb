module QDC
   # To avoid a single directory with tens of thousands of files, break
   # up the PID into 3 digit sub directories.
   #
   def self.relative_pid_path( pid )
      pid_parts = pid.split(":")
      base = pid_parts[1]
      parts = base.scan(/.../) # break up into 3 digit sections, but this can leave off last digit
      parts << base.last if parts.length * 3 !=  base.length  # get last digit if necessary
      pid_dirs = parts.join("/")
      return File.join(pid_parts[0], pid_dirs)
   end

   def self.crosswalk_creator(doc)
      out = []
      concat_names = []
      curr_name = {}
      doc.xpath("/mods/name/namePart").each do |n|
         if n.attribute("type") == "primary" || n.attribute("nameTitleGroup") == "1"
            return ["<dcterms:creator>#{clean_xml_text(n.text)}</dcterms:creator>"]
         end

         if n.attribute("type") == "family"
            if curr_name.has_key? :family
               concat_names << curr_name
               curr_name = {family: clean_xml_text(n.text) }
            else
               curr_name[:family] = clean_xml_text(n.text)
            end
         elsif  n.attribute("type") == "given"
            if curr_name.has_key? :given
               concat_names << curr_name
               curr_name = {given: clean_xml_text(n.text) }
            else
               curr_name[:given] = clean_xml_text(n.text)
            end
         elsif n.attribute("type") == "date"
            if curr_name.has_key? :date
               concat_names << curr_name
               curr_name = {date: clean_xml_text(n.text) }
            else
               curr_name[:date] = clean_xml_text(n.text)
            end
         else
            if curr_name.keys.size > 0
               concat_names << curr_name
               curr_name = {}
            end
            out << "<dcterms:creator>#{clean_xml_text(n.text)}</dcterms:creator>"
         end
      end

      if curr_name.keys.size > 0
         concat_names << curr_name
         curr_name = {}
      end

      concat_names.each do |n|
         name = n[:family]
         if !n[:given].blank?
            name << ", #{n[:given]}"
         end
         if !n[:date].blank?
            name << ", #{n[:date]}"
         end
         out << "<dcterms:creator>#{name}</dcterms:creator>"
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
      ["namePart", "hierarchicalGeographic", "subject/topic", "subject/name"].each do |k|
         if xpath.include?(k)
            include_value = true
            break
         end
      end

      n = doc.at_xpath(xpath)
      if !n.nil?
         txt = clean_xml_text(n.text)
         txt = "Image" if txt == "still image"
         txt = "Text" if txt == "text"
         val = n.attribute("valueURI")
         if !val.blank? && include_value
            return "<dcterms:#{qdc_ele} valueURI=\"#{val}\">#{txt}</dcterms:#{qdc_ele}>"
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
         next if !n.attribute("objectPart").blank?
         txt = clean_xml_text(n.text)
         val = n.attribute("valueURI")
         if val.blank?  || xpath.include?("genre") == false
           out << "<#{qdc_ns}:#{qdc_ele}>#{txt}</#{qdc_ns}:#{qdc_ele}>"
        else
           out << "<#{qdc_ns}:#{qdc_ele} valueURI=\"#{val}\">#{txt}</#{qdc_ns}:#{qdc_ele}>"
        end
      end
      return out
   end

   # Crosswalk data in MODS /mods/originInfo/dateIssued and /mods/originInfo/dateCreated
   # to QDC dcterms:created.
   #
   def self.crosswalk_date_created(doc, metadata_type)
      out = []
      if metadata_type == "SirsiMetadata"
         # Per Jeremy for SIRSI sources, just return dateCreated and dateIssued
         doc.xpath("/mods/originInfo/dateCreated").each do |n|
            out << "<dcterms:created>#{clean_xml_text(n.text)}</dcterms:created>"
         end
         doc.xpath("/mods/originInfo/datedateIssued ").each do |n|
            out << "<dcterms:created>#{clean_xml_text(n.text)}</dcterms:created>"
         end
         return out
      elsif metadata_type == "XmlMetadata"
         # Notes from Jeremy for XML sources:
         #   if there are multiple dateCreated and attributes point="start"
         #   and point="end", map both to a single date like start/end. If not, use the
         #   one with attribute keyDate="yes"
         dates = []
         start_date = end_date = ""
         doc.xpath("/mods/originInfo/dateCreated").each do |n|
            if n.attribute("keyDate") == "yes"
               # key date short-circuits and returns immediately
               out << "<dcterms:created>#{clean_xml_text(n.text)}</dcterms:created>"
               return out
            elsif n.attribute("point") == "start"
               start_date = clean_xml_text(n.text)
            elsif n.attribute("point") == "end"
               end_date = clean_xml_text(n.text)
            end
            # track all dates found
            dates << clean_xml_text(n.text)
         end
      end

      if !start_date.blank? && !end_date.blank?
         out << "<dcterms:created>#{start_date}/#{end_date}</dcterms:created>"
      else
         dates.each { |d| out << "<dcterms:created>#{d}</dcterms:created>" }
      end

      return out
   end

   def self.crosswalk_subject_name(doc, metadata_type)
      if metadata_type == "XmlMetadata"
         return QDC.crosswalk_multi(doc, "/mods/subject/name", "dcterms", "subject")
      end
      out = []
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
      out << "<dcterms:subject>#{curr}/</dcterms:subject>" if !curr.blank?
      return out
   end

   # Convert illegal XML characters to safe. These are: &, < and >
   #
   def self.clean_xml_text(val)
      clean = val.strip
      clean = clean.gsub(/&/, "&amp;").gsub(/</,"&lt;").gsub(/>/,"&gt;")
      return clean
   end

end
