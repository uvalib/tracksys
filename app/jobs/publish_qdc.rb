
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

      logger.info("Pull latest version from git to #{qdc_dir}...")
      git = Git.open(qdc_dir, :log => logger )
      git.config('user.name', Settings.dpla_qdc_git_user )
      git.config('user.email', Settings.dpla_qdc_git_email )
      git.pull

      # Generate QDC and write it to delivery directory. The full path
      # to the QDC file created is returned.
      qdc_fn = PublishQDC.generate_qdc(meta, qdc_dir, qdc_tpl, logger)

      if git.diff.size > 0
         logger.info("Publishing changes to git...")
         git.add(qdc_fn)
         git.commit( "Update to #{meta.pid}" )
         git.push
         meta.update(qdc_generated_at: DateTime.now)
      else
         logger.info "Publication resulted in no changes from prior version. Nothing more to do."
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

      log.info("Select exemplar...")
      exemplar_pid = meta.master_files.first.pid
      if !meta.exemplar.blank?
         exemplar = meta.master_files.find_by(filename: meta.exemplar)
         if !exemplar.nil?
            exemplar_pid = exemplar.pid
         end
      end

      # ingest into an XML document and do a manual crosswalk to get data
      log.info("Collect metadata...")
      doc = Nokogiri::XML( Hydra.desc(meta) )
      doc.remove_namespaces!

      # Populate data that is common between XML/Sirsi metadat first
      cw_data = {}
      cw_data['EXEMPLAR'] = exemplar_pid
      cw_data['TITLE'] = meta.title
      cw_data['RIGHTS'] = meta.use_right.uri
      cw_data['TERMS'] = []

      cw_data['TERMS'].concat( QDC.crosswalk_creator(doc) )
      cw_data['TERMS'].concat( QDC.crosswalk_date_created(doc, meta.type) )
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/abstract", "description")
      cw_data['TERMS'].concat( QDC.crosswalk_multi(doc, "/mods/physicalDescription/form", "dcterms", "medium") )
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/physicalDescription/extent", "extent")
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/originInfo/publisher", "publisher")
      cw_data['TERMS'].concat( QDC.crosswalk_multi(doc, "/mods/subject/topic", "dcterms", "subject") )
      cw_data['TERMS'].concat( QDC.crosswalk_subject_name(doc, meta.type) )
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/typeOfResource", "type")
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/subject/hierarchicalGeographic/country", "spatial")
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/subject/hierarchicalGeographic/state", "spatial")
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/subject/hierarchicalGeographic/city", "spatial")
      cw_data['TERMS'] << QDC.crosswalk(doc, "/mods/subject/hierarchicalGeographic/county", "spatial")

      cw_data['TERMS'].concat( QDC.crosswalk_multi(doc, "/mods/language/languageTerm", "dcterms", "language") )
      cw_data['TERMS'].concat( QDC.crosswalk_multi(doc, "/mods/relatedItem[@type='series'][@displayLabel='Part of']/titleInfo/title", "dcterms", "isPartOf") )
      cw_data['TERMS'].concat( QDC.crosswalk_multi(doc, "/mods/genre", "edm", "hasType") )
      cw_data['TERMS'].concat( QDC.crosswalk_multi(doc, "/mods/subject/temporal", "dcterms", "temporal") )


      # Clean up data and populate XML template...
      log.info("Populate QDC XML template...")
      cw_data['TERMS'].compact!
      qdc = qdc_tpl.gsub(/PID/, meta.pid)
      cw_data.each do |k,v|
         if k == "TERMS"
            qdc.gsub!(/#{k}/, v.join("\n    "))
         else
            qdc.gsub!(/#{k}/, v)
         end
      end

      # Write QDC file to filesystem
      log.info("Write QDC file to #{qdc_fn}...")
      out = File.open(qdc_fn, "w")
      out.write(qdc)
      out.close

      return qdc_fn
   end
end
