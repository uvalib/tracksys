class FinalizeUnit < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      @unit =  Unit.find( message[:unit_id] )
      if @unit.reorder
         fatal_error("Unit directory #{unit_id} is a re-order and should not be finalized.")
      end

      act = "begins"
      act = "restarts" if @unit.unit_status == "error"
      src_dir = File.join(Settings.production_mount, "finalization", @unit.directory)
      if !@unit.project.nil?
         @project = @unit.project
         logger.info "Project #{@project.id}, unit #{@unit.id} #{act} finalization."
      else
         logger.info "Unit #{@unit.id} #{act} finalization without project."
      end

      # ensure finilzation directory exists
      if !Dir.exists? src_dir
         fatal_error("Finalization directory #{src_dir} does not exist")
      end

      # manage unit status
      if @unit.unit_status == "finalizing"
         fatal_error "Unit #{@unit.id} is already finalizaing."
      elsif @unit.unit_status == "approved"
         @unit.order.update(date_finalization_begun: Time.now)
         logger.info("Date Finalization Begun updated for order #{@unit.order.id}")
      elsif @unit.unit_status != 'error'
         fatal_error "Unit #{@unit.id} has not been approved."
      end
      @unit.update(unit_status: "finalizing")

      begin
         # Perform basic QA on unit settings and filesystem contents.
         # These are safe to repeat overy time finalization is started/restarted
         qa_unit_data()
         qa_filesystem(src_dir)

         # Create all of the master files, publish to IIIF then archive the unit
         Images.import(@unit, logger)

         # If OCR has been requested, do it AFTER archive (OCR requires tif to be in archive)
         # but before deliverable generation (deliverables require OCR text to be present)
         if @unit.ocr_master_files
            OCR.synchronous(@unit, self)
            @unit.reload
         end

         # Flag unit for Virgo publication?
         if @unit.include_in_dl
            Virgo.publish(@unit, logger)
         end

         # If desc is not digital collection building, create patron deliverables regardless of any other settings
         if @unit.intended_use.description != "Digital Collection Building"
            create_patron_deliverables()
         end
      rescue Exception => e
         if !@project.nil?
            prob = Problem.find_by(label: "Finalization")
            note = Note.create(staff_member: @project.owner, project: @project, note_type: :problem, note:  e.message , step: @project.current_step )
            note.problems << prob
            @project.active_assignment.update(status: :error )
         end
         fatal_error( e.message )
      end

      # At this point, finalization has completed successfully and project is done
      if !@project.nil?
         logger().info "Unit #{@unit.id} finished finalization; updating project."
         @project.finalization_success( status() )
      else
         logger().info "Unit #{@unit.id} finished finalization"
      end
      @unit.update(unit_status: "done")

      # Cleanup any tmo directories and move unit to ready_to_delete
      Images.cleanup(@unit, logger)
   end

   # Perfrom QA on unit / order settings. This is the first step in finalization
   private
   def qa_unit_data
      logger.info "QA unit #{@unit.id} data"

      # First, check if unit is assigned to metadata record. This is an immediate fail
      if @unit.metadata.nil?
         fatal_error "Unit #{@unit.id} is not assigned to a metadata record."
      end

      if @unit.include_in_dl == false && @unit.reorder == false
         check_auto_publish
      end

      has_failures = false
      if @unit.include_in_dl && @unit.metadata.availability_policy_id.blank? && @unit.metadata.type != "ExternalMetadata"
         log_failure "Availability policy must be set for all units flagged for inclusion in the DL"
         has_failures = true
      end

      if @unit.intended_use.blank?
         log_failure "Unit #{@unit.id} has no intended use.  All units that participate in this workflow must have an intended use."
         has_failures = true
      end

      # fail for no ocr hint or incompatible hint / ocr Settings
      if @unit.metadata.ocr_hint_id.nil?
         log_failure "Unit metadata #{@unit.metadata.id} has no OCR Hint. This is a required setting."
         has_failures = true
      else
         if @unit.ocr_master_files
            if !@unit.metadata.ocr_hint.ocr_candidate
               log_failure "Unit is flagged to perform OCR, but the metadata setting indicates OCR is not possible."
               has_failures = true
            end
            if @unit.metadata.ocr_language_hint.nil?
               log_failure "Unit is flagged to perform OCR, but the required language hint for metadata #{@unit.metadata.id} is not set"
               has_failures = true
            end
         end
      end

      if @unit.include_in_dl && @unit.throw_away
         log_failure "Throw away units cannot be flagged for publication to the DL."
         has_failures = true
      end

      order = @unit.order
      if not order.date_order_approved?
         logger.info "Order #{order.id} is not marked as approved.  Since this unit is undergoing finalization, the workflow has automatically updated this value and changed the order_status to approved."
         if !order.update(date_order_approved: Time.now, order_status: 'approved')
            fatal_error( order.errors.full_messages.to_sentence )
         end
      end

      if has_failures
         fatal_error "Unit #{@unit.id} has failed the QA Unit Data Processor"
      end
   end

   # Perfrom QA on the unit filesystem
   private
   def qa_filesystem(src_dir)
      logger.info "QA filesystem for #{src_dir}"

      has_failures = false
      tif_files = []
      Dir.glob(File.join(src_dir, "**/*")).each do |dir_entry|
         next if File.directory? dir_entry   # skip directories
         if (dir_entry =~ /.tif$/)
            tif_files << dir_entry
         elsif (dir_entry !~ /.txt$/)        # safe to ignore (.txt files are OCR data typically)
            log_failure "#{src_dir} contains unexpected or non-standard file: #{File.basename(dir_entry)}."
            has_failures = true
         end
      end

      # Checking for:
      # 1. Existence of TIF files.
      # 2. The number of content files in the directory equals the sequence number of the last file.
      # 3. All TIF files conform to the naming convention.
      # 4. No file is less than 1MB (1MB being a size arbitrarily determined to represent a "too small" file)
      logger.info "Check content files..."
      tif_files.sort!

      if tif_files.empty?
         log_failure "There are no .tif files in the directory."
         has_failures = true
      end

      # constants for QA checks
      minimum_size=2048
      regex_tif_file = Regexp.new('_\d{4}.(tif)$')

      max_sequence_num = -1
      max_seq_file = ""
      tif_files.each do |tif_file_path|
         tif_file = File.basename(tif_file_path)

         # extract the sequence num from the name: unit_SEQ.tif
         seq = tif_file.split("_")[1].split(".")[0].to_i
         if seq > max_sequence_num
            max_sequence_num = seq
            max_seq_file = tif_file
         end

         if tif_file !~ /^#{@unit.directory}/
            log_failure "#{tif_file} does not start with the correct unit prefix #{@unit.directory}"
            has_failures = true
         end

         if regex_tif_file.match(tif_file).nil?
            log_failure "#{tif_file} has an incorrectly formatted sequence number or extension."
            has_failures = true
         end

         if File.size(tif_file_path) < minimum_size
            log_failure "#{tif_file} is less than #{minimum_size} bytes large and is very likely an incorrect file."
            has_failures = true
         end
      end

      if max_sequence_num != tif_files.length
         log_failure  "The number of tif files in directory (#{tif_files.length}) does not equal the sequence number of the last file (#{max_seq_file})."
         has_failures = true
      end

      if has_failures
         fatal_error "Unit #{@unit.id} has failed the Filesystem QA."
      end
   end

   private
   def check_auto_publish()
      logger.info "Checking unit #{@unit.id} for auto-publish"
      if @unit.complete_scan == false
         logger.info "Unit #{@unit.id} is not a complete scan and cannot be auto-published"
         return
      end

      metadata = @unit.metadata
      if metadata.is_manuscript || metadata.is_personal_item
         logger.info "Unit #{@unit.id} is for a manuscript or personal item and cannot be auto-published"
         return
      end

      if metadata.type != "SirsiMetadata"
         logger.info "Unit #{@unit.id} metadata is not from Sirsi and cannot be auto-published"
         return
      end

      # convert to SirsiMetadata so we can get at catalog_key and barcode.
      # Need this to check publication year before 1923
      sirsi_meta = metadata.becomes(SirsiMetadata)
      pub_info = Virgo.get_marc_publication_info(sirsi_meta.catalog_key)
      if !pub_info[:year].blank? && pub_info[:year].to_i < 1923
         logger.info "Unit #{@unit.id} is a candidate for auto-publishing."
         if sirsi_meta.availability_policy.nil?
            sirsi_meta.update(availability_policy_id: 1)
         end
         @unit.update(include_in_dl: true)
         logger.info "Unit #{@unit.id} successfully flagged for DL publication"
      else
         logger.info "Unit #{@unit.id} has no date or a date after 1923 and cannot be auto-published"
      end
   end

   private
   def create_patron_deliverables()
      if @unit.intended_use.deliverable_format == "pdf"
         logger.info("Unit #{@unit.id} requires the creation of PDF patron deliverables.")
         Patron.pdf_deliverable(@unit, logger)
      else
         Patron.zip_deliverables(@unit, logger)
      end

      @unit.update(date_patron_deliverables_ready: Time.now)
      logger.info("All patron deliverables created")

      # check for completeness, fees and generate manifest PDF. Same for all patron deliverables
      CheckOrderReadyForDelivery.exec_now( { order_id: @unit.order_id}, self  )
   end

   # Override fatal error and mark the unit as status 'error'
   def fatal_error(err)
      @unit.update!(unit_status: "error")
      super
   end

   # Override the normal delayed_job failure hook to pass the problem info back to the project
   def failure(job)
      if !@project.nil?
         logger().fatal "Unit #{@project.unit.id} failed Finalization"
         @project.finalization_failure( status() )
      end
   end
end
