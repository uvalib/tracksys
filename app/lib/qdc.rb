module QDC

   # Generate the QDC record for a metadata item
   #
   def self.generate(meta)
      Delayed::Worker.logger.info("====> Generate QDC for #{meta.pid}")

      Delayed::Worker.logger.info("Reading QDC template")
      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      # determine where to put output file (split pid up into 3 digit segments to avoid massive directory listing)
      relative_pid_path = relative_pid_path(meta.pid)
      pid_path = File.join(qdc_dir, relative_pid_path)
      FileUtils.mkdir_p pid_path if !Dir.exist?(pid_path)
      qdc_fn = File.join(pid_path, "#{meta.pid}.xml")

      Delayed::Worker.logger.info("Select exemplar...")
      exemplar_pid = meta.master_files.first.pid
      if !meta.exemplar.blank?
         exemplar = meta.master_files.find_by(filename: meta.exemplar)
         if !exemplar.nil?
            exemplar_pid = exemplar.pid
         end
      end

      # ingest into an XML document and do a manual crosswalk to get data
      Delayed::Worker.logger.info("Collect metadata...")
      doc = Nokogiri::XML( Hydra.desc(meta) )
      doc.remove_namespaces!
      cw_data = {}
      cw_data['EXEMPLAR'] = exemplar_pid
      cw_data['TITLE'] = meta.title
      cw_data['RIGHTS'] = meta.use_right.uri
      cw_data['TERMS'] = []

      # Creator Name
      # in this order: usage=primary, personal, first one
      cn  = doc.at_xpath("//name[@usage='primary']")
      cn = doc.at_xpath("//name[@type='personal']") if cn.blank?
      cn = doc.at_xpath("//name") if cn.blank?
      if !cn.blank?
         cw_data['CREATOR'] = ""
         cn.xpath("namePart").each do |n|
            cw_data['CREATOR'] << " " if cw_data['CREATOR'].length > 0
            cw_data['CREATOR'] << clean_xml_text(n.text)
         end
      end

      # Date Created
      n = doc.at_xpath("//originInfo/dateCreated[@keyDate='yes']")
      n = doc.at_xpath("//originInfo/dateIssued") if n.nil?
      if !n.nil?
         cw_data['TERMS'] <<
            "<dcterms:created>#{clean_xml_text(n.text)}</dcterms:created>" if n.text != "undated"
      end

      cw_data['TERMS'] << crosswalk(doc, "//identifier[@type='accessionNumber']", "identifier")
      cw_data['TERMS'] << crosswalk(doc, "//abstract", "description")
      cw_data['TERMS'] << crosswalk(doc, "//physicalDescription/form", "medium")
      cw_data['TERMS'] << crosswalk(doc, "//physicalDescription/extent", "extent")
      cw_data['TERMS'] << crosswalk(doc, "//language/languageTerm", "language")
      cw_data['TERMS'] << crosswalk(doc, "//originInfo/publisher", "publisher")
      cw_data['TERMS'] << crosswalk(doc, "//subject/topic", "subject")
      cw_data['TERMS'] << crosswalk(doc, "//subject/name", "subject")
      cw_data['TERMS'] << crosswalk(doc, "//typeOfResource", "type")
      cw_data['TERMS'] << crosswalk(doc, "//relatedItem[@type='series'][@displayLabel='Part of']/titleInfo/title", "isPartOf")

      # <subject><hierarchicalGeographic> -> dcterms:spatial
      nd = doc.at_xpath("//subject/hierarchicalGeographic")
      if !nd.nil?
         out = ""
         ["country", "state", "city"].each do |t|
            p = doc.at_xpath("//subject/hierarchicalGeographic/#{t}")
            if !p.nil?
               out << ", " if out.length > 0
               out << clean_xml_text(p.text)
            end
         end
         if out.length > 0
            cw_data['TERMS'] << "<dcterms:spatial>#{out}</dcterms:spatial>"
         end
      end

      cw_data['TERMS'].compact!
      qdc = qdc_tpl.gsub(/PID/, meta.pid)
      cw_data.each do |k,v|
         if k == "TERMS"
            qdc.gsub!(/#{k}/, v.join("\n    "))
         else
            qdc.gsub!(/#{k}/, v)
         end
      end

      # write QDC file to filesystem
      Delayed::Worker.logger.info("Write QDC file to #{qdc_fn}...")
      out = File.open(qdc_fn, "w")
      out.write(qdc)
      out.close

      # TAKE THIS OUT! Causes loop of update
      #meta.update(qdc_generated_at: DateTime.now)
   end

   # Publish a QDC record to the DPLAVA github repo
   #
   def self.publish(metadata)
      Delayed::Worker.logger.debug("====> Publish QDC for #{metadata.pid}")
      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      msg = "Update to #{metadata.pid}"
      usr = "-c \"user.name=#{Settings.qdc_git_user}\" -c \"user.email=#{Settings.qdc_git_email}\""
      cmd = "cd #{qdc_dir}; git add .; git commit -m '#{msg}'; git push"
      `#{cmd}`
   end

   private
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
