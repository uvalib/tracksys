module QDC
   def self.relative_pid_path( pid )
      pid_parts = pid.split(":")
      base = pid_parts[1]
      parts = base.scan(/.../) # break up into 3 digit sections, but this can leave off last digit
      parts << base.last if parts.length * 3 !=  base.length  # get last digit if necessary
      pid_dirs = parts.join("/")
      return File.join(pid_parts[0], pid_dirs)
   end

   def self.crosswalk(doc, xpath, qdc_ele)
      n = doc.at_xpath(xpath)
      if !n.nil?
         return "<dcterms:#{qdc_ele}>#{clean_xml_text(n.text)}</dcterms:#{qdc_ele}>"
      end
      return nil
   end

   def self.clean_xml_text(val)
      clean = val.strip
      clean = clean.gsub(/&/, "&amp;").gsub(/</,"&lt;").gsub(/>/,"&gt;")
      return clean
   end

end
