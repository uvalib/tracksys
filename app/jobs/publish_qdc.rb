
class PublishQDC < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Metadata", :originator_id=>message[:metadata_id] )
   end

   def do_workflow(message)
      raise "Parameter 'metadata_id' is required" if message[:metadata_id].blank?
      meta = Metadata.find(message[:metadata_id])
      if !meta.in_dpla?
         on_error("Metadata #{meta.id} is not in QPLA and does not need QDC to be published")
      end

      logger.info("Reading QDC template")
      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      # determine where to put output file (split pid up into 3 digit segments to avoid massive directory listing)
      relative_pid_path = QDC.relative_pid_path(meta.pid)
      pid_path = File.join(qdc_dir, relative_pid_path)
      FileUtils.mkdir_p pid_path if !Dir.exist?(pid_path)
      qdc_fn = File.join(pid_path, "#{meta.pid}.xml")

      logger.info("Select exemplar...")
      exemplar_pid = meta.master_files.first.pid
      if !meta.exemplar.blank?
         exemplar = meta.master_files.find_by(filename: meta.exemplar)
         if !exemplar.nil?
            exemplar_pid = exemplar.pid
         end
      end

      # ingest into an XML document and do a manual crosswalk to get data
      logger.info("Collect metadata...")
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
            cw_data['CREATOR'] << QDC.clean_xml_text(n.text)
         end
      end

      # Date Created
      n = doc.at_xpath("//originInfo/dateCreated[@keyDate='yes']")
      n = doc.at_xpath("//originInfo/dateIssued") if n.nil?
      if !n.nil?
         cw_data['TERMS'] <<
            "<dcterms:created>#{QDC.clean_xml_text(n.text)}</dcterms:created>" if n.text != "undated"
      end

      cw_data['TERMS'] << QDC.crosswalk(doc, "//identifier[@type='accessionNumber']", "identifier")
      cw_data['TERMS'] << QDC.crosswalk(doc, "//abstract", "description")
      cw_data['TERMS'] << QDC.crosswalk(doc, "//physicalDescription/form", "medium")
      cw_data['TERMS'] << QDC.crosswalk(doc, "//physicalDescription/extent", "extent")
      cw_data['TERMS'] << QDC.crosswalk(doc, "//language/languageTerm", "language")
      cw_data['TERMS'] << QDC.crosswalk(doc, "//originInfo/publisher", "publisher")
      cw_data['TERMS'] << QDC.crosswalk(doc, "//subject/topic", "subject")
      cw_data['TERMS'] << QDC.crosswalk(doc, "//subject/name", "subject")
      cw_data['TERMS'] << QDC.crosswalk(doc, "//typeOfResource", "type")
      cw_data['TERMS'] << QDC.crosswalk(doc, "//relatedItem[@type='series'][@displayLabel='Part of']/titleInfo/title", "isPartOf")

      # <subject><hierarchicalGeographic> -> dcterms:spatial
      nd = doc.at_xpath("//subject/hierarchicalGeographic")
      if !nd.nil?
         out = ""
         ["country", "state", "city"].each do |t|
            p = doc.at_xpath("//subject/hierarchicalGeographic/#{t}")
            if !p.nil?
               out << ", " if out.length > 0
               out << QDC.clean_xml_text(p.text)
            end
         end
         if out.length > 0
            cw_data['TERMS'] << "<dcterms:spatial>#{out}</dcterms:spatial>"
         end
      end

      # Clean up data and populate XML template...
      logger.info("Populate QDC XML template...")
      cw_data['TERMS'].compact!
      qdc = qdc_tpl.gsub(/PID/, meta.pid)
      cw_data.each do |k,v|
         if k == "TERMS"
            qdc.gsub!(/#{k}/, v.join("\n    "))
         else
            qdc.gsub!(/#{k}/, v)
         end
      end

      # Ensure files are up to date from git, then write QDC file to filesystem
      cmd = "cd #{qdc_dir}; git pull"
      `#{cmd}`
      logger.info("Write QDC file to #{qdc_fn}...")
      out = File.open(qdc_fn, "w")
      out.write(qdc)
      out.close

      logger.info("Publishing changes to git...")
      msg = "Update to #{meta.pid}"
      usr = "-c \"user.name=#{Settings.qdc_git_user}\" -c \"user.email=#{Settings.qdc_git_email}\""
      cmd = "cd #{qdc_dir}; git add .; git commit -m '#{msg}'; git push"
      `#{cmd}`

      # set timestamp when this QDC was most recently updated
      meta.update(qdc_generated_at: DateTime.now)
   end
end
