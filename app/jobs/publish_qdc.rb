
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

      if Rails.env == "production"
         logger.info("Pull latest version from git to #{qdc_dir}...")
         git = Git.open(qdc_dir, :log => logger )
         git.config('user.name', Settings.dpla_qdc_git_user )
         git.config('user.email', Settings.dpla_qdc_git_email )
         git.pull
      end

      # Generate QDC and write it to delivery directory. The full path
      # to the QDC file created is returned.
      qdc_fn = PublishQDC.generate_qdc(meta, qdc_dir, qdc_tpl, logger)

      if Rails.env == "production"
         if git.diff.size > 0
            logger.info("Publishing changes to git...")
            git.add(qdc_fn)
            git.commit( "Update to #{meta.pid}" )
            git.push
            meta.update(qdc_generated_at: DateTime.now)
         else
            logger.info "Publication resulted in no changes from prior version. Nothing more to do."
         end
      else
         meta.update(qdc_generated_at: DateTime.now)
      end
   end

   # Generate the QDC; return the full path to the QDC file generated
   #
   def self.generate_qdc(meta, qdc_dir, qdc_tpl, log = Logger.new(STDOUT) )

      # determine where to put output file (split pid up into 3 digit segments to avoid massive directory listing)
      relative_pid_path = QDC.relative_pid_path(meta.pid)
      pid_path = File.join(qdc_dir, relative_pid_path)
      FileUtils.mkdir_p pid_path if !Dir.exist?(pid_path)
      qdc_fn = File.join(pid_path, "#{meta.pid}.xml")

      # Make sure the exemplar doesnt have filesize=507620. This equates to an image with text 
      # 'Original Image Missing'. Instead of the IIIF URL, include this text: 'original image missing'
      log.info("Select exemplarPID...")
      if meta.has_exemplar?
         exemplar_info = meta.exemplar_info
         if exemplar_info[:filesize] == 507620 
            log.info("Exemplar matches filesize for missing thumb. Replace IIIF with text")
            preview = "original image missing"
         else 
            preview = "https://iiif.lib.virginia.edu/iiif/#{exemplar_info[:pid]}/full/!300,300/0/default.jpg"
         end
      else
         ex_mf = meta.master_files.first
         if ex_mf.filesize == 507620 
            log.info("Exemplar matches filesize for missing thumb. Replace IIIF with text")
            preview = "original image missing"
         else 
            preview = "https://iiif.lib.virginia.edu/iiif/#{ex_mf.pid}/full/!300,300/0/default.jpg"
         end
      end

      # ingest into an XML document and do a manual crosswalk to get data
      log.info("Collect metadata...")
      doc = Nokogiri::XML( Hydra.desc(meta) )
      doc.remove_namespaces!

      # Populate data that is common between XML/Sirsi metadat first
      cw_data = {}
      cw_data['PREVIEW'] = preview
      cw_data['TITLE'] = QDC.clean_xml_text(meta.title)
      if cw_data['TITLE'].downcase == "untitled"
         log.info("This item has title 'untitled'. Skipping.")
         if File.exist? qdc_fn
            log.info "Skipped item has file #{qdc_fn}; removing it"
         end
         return nil
      end

      cw_data['RIGHTS'] = meta.use_right.uri
      cw_data['TERMS'] = []

      # Special handling for Visual History. Rights are complicated... need to
      # check for specific items in the collection and assign rights to them that
      # may be different from those in tracksys. IF the item is not one of the specificly
      # accepted ones, skip it as UVA doesn't have clear rights to publish it.
      if QDC.is_visual_history?(doc, meta)
         vh_rights_uri = QDC.visual_history_rights(doc)
         if vh_rights_uri.nil?
            log.info("This visual history item has use rights issues. Skipping")
            if File.exist? qdc_fn
               log.info "Skipped item has file #{qdc_fn}; removing it"
            end
            return nil
         else
            cw_data['RIGHTS'] = vh_rights_uri
         end
      end

      cw_data['TERMS'].concat( QDC.crosswalk_name(doc, "/mods/name", "dcterms", "creator") )
      cw_data['TERMS'].concat( QDC.crosswalk_date_created(doc, meta.type) )
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/abstract", "description")
      cw_data['TERMS'].concat( QDC.crosswalk_multi(doc, "/mods/physicalDescription/form", "dcterms", "medium") )
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/physicalDescription/extent", "extent")
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/originInfo/publisher", "publisher")
      cw_data['TERMS'].concat( QDC.crosswalk_name(doc, "/mods/subject/name", "dcterms", "subject") )
      cw_data['TERMS'].concat( QDC.crosswalk_subject(doc) )
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/subject/hierarchicalGeographic/country", "spatial")
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/subject/hierarchicalGeographic/state", "spatial")
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/subject/hierarchicalGeographic/city", "spatial")
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/subject/hierarchicalGeographic/county", "spatial")

      cw_data['TERMS'].concat( QDC.crosswalk_multi(doc, "/mods/language/languageTerm", "dcterms", "language") )
      cw_data['TERMS'].concat( QDC.crosswalk_multi(doc, "/mods/relatedItem[@type='series'][@displayLabel='Part of']/titleInfo/title", "dcterms", "isPartOf") )
      cw_data['TERMS'].concat( QDC.crosswalk_multi(doc, "/mods/genre", "edm", "hasType") )
      cw_data['TERMS'].concat( QDC.crosswalk_type_of_resource(doc) )


      # Clean up data and populate XML template...
      cw_data['TERMS'].compact!
      log.info("Populate QDC XML template with [#{cw_data}]...")
      qdc = qdc_tpl.gsub(/PID/, meta.pid)
      cw_data.each do |k,v|
         if k == "TERMS"
            qdc.gsub!(/#{k}/, v.join("\n    "))
         else
            qdc.gsub!(/#{k}/, v)
         end
      end

      # Write QDC file to filesystem
      log.info("Write QDC file to #{qdc_fn}")
      out = File.open(qdc_fn, "w")
      out.write(qdc)
      out.close

      return qdc_fn
   end
end
