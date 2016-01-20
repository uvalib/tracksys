class CopyUnitForDeliverableGeneration < BaseJob

   def perform(message)
      Job_Log.debug "CopyUnitForDeliverableGenerationProcessor received: #{message.to_json}"

      @mode = message[:mode]
      @unit_id = message[:unit_id]
      @source_dir = message[:source_dir]
      @unit_dir = "%09d" % @unit_id
      @working_unit = Unit.find(@unit_id)
      @messagable_id = message[:unit_id]
      @messagable_type = "Unit"
      set_workflow_type()
      @master_files = @working_unit.master_files
      @failure_messages = Array.new

      if @mode == "both"
         @modes = ['dl', 'patron']
      else
         @modes = ["#{@mode}"]
      end

      @modes.each do |mode|
         @destination_dir = File.join(PROCESS_DELIVERABLES_DIR, mode, @unit_dir)
         FileUtils.mkdir_p(@destination_dir)

         @master_files.each do |master_file|
            begin
               Job_Log.debug("Copy from #{@source_dir} to #{@destination_dir}/#{master_file.filename}")
               FileUtils.cp(File.join(@source_dir, master_file.filename), File.join(@destination_dir, master_file.filename))
            rescue Exception => e
               @failure_messages << "Can't copy source file '#{master_file.filename}': #{e.message}"
            end

            # compare MD5 checksums
            source_md5 = Digest::MD5.hexdigest(File.read(File.join(@source_dir, master_file.filename)))
            dest_md5 = Digest::MD5.hexdigest(File.read(File.join(@destination_dir, master_file.filename)))
            if source_md5 != dest_md5
               @failure_messages << "Failed to copy source file '#{master_file.filename}': MD5 checksums do not match"
            end
         end
      end

      if @failure_messages.empty?
         if @mode == 'patron'
            QueueUnitDeliverables.exec_now({ :unit_id => @unit_id, :mode => @mode, :source => @destination_dir })
            on_success "Unit #{@unit_id} has been successfully copied to #{@destination_dir} so patron deliverables can be made."
         elsif @mode == 'dl'
            UpdateUnitDateQueuedForIngest.exec_now({ :unit_id => @unit_id, :mode => @mode, :source => @destination_dir })
            on_success "Unit #{@unit_id} has been successfully copied to #{@destination_dir} so Digital Library deliverables can be made."
         elsif @mode == 'both'
            local_mode = "patron"
            QueueUnitDeliverables.exec_now({ :unit_id => @unit_id, :mode => local_mode, :source => @destination_dir })

            local_mode = "dl"
            UpdateUnitDateQueuedForIngest.exec_now({ :unit_id => @unit_id, :mode => local_mode, :source => @destination_dir })
            on_success "Unit #{@unit_id} has been successfully copied to both the DL and patron process directories"
         else
            on_error "Unknown @mode passed to copy_unit_for_deliverable_generation_processor"
         end

         # If a unit has not already been archived (i.e. this unit did not arrive at this processor from start_ingest_from_archive) archive it.
         if not @working_unit.date_archived
            on_success "Because this unit has not already been archived, it is being sent to the archive."
            #SendUnitToArchive.exec_now({ :unit_id => @unit_id, :internal_dir => 'yes', :source_dir => IN_PROCESS_DIR })
         end
      else
         @failure_messages.each do |message|
            on_failure "#{message}"
         end
         on_error "There were failures in the copying process."
      end
   end
end
