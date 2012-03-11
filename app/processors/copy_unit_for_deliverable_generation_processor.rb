class CopyUnitForDeliverableGenerationProcessor < ApplicationProcessor

  subscribes_to :copy_unit_for_deliverable_generation, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :queue_unit_deliverables
  publishes_to :send_unit_to_archive
  publishes_to :update_unit_date_queued_for_ingest

  def on_message(message)
    logger.debug "CopyUnitForDeliverableGenerationProcessor received: " + message.to_s

    hash = ActiveSupport::JSON.decode(message).symbolize_keys 

    @mode = hash[:mode]
    @unit_id = hash[:unit_id]  
    @source_dir = hash[:source_dir]

    @unit_dir = "%09d" % @unit_id
    @working_unit = Unit.find(@unit_id)
    @messagable = @working_unit
    @master_files = @working_unit.master_files
    @failure_messages = Array.new

    if @mode == "both"
      @modes = ['dl', 'patron']
    else
      @modes = ["#{@mode}"]
    end

    @modes.each {|mode|
      @destination_dir = File.join(PROCESS_DELIVERABLES_DIR, mode, @unit_dir)
      FileUtils.mkdir_p(@destination_dir)

      @master_files.each {|master_file|
        begin
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
      }
    }

    if @failure_messages.empty?
      if @mode == 'patron'
        message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :mode => @mode, :source => @destination_dir })
        publish :queue_unit_deliverables, message
        on_success "Unit #{@unit_id} has been successfully copied to #{@destination_dir} so patron deliverables can be made."
      elsif @mode == 'dl'
        message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :mode => @mode, :source => @destination_dir })
        publish :update_unit_date_queued_for_ingest, message
        on_success "Unit #{@unit_id} has been successfully copied to #{@destination_dir} so Digital Library deliverables can be made."
      elsif @mode == 'both'
        local_mode = "patron"
        message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :mode => local_mode, :source => @destination_dir })
        publish :queue_unit_deliverables, message

        local_mode = "dl"
        message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :mode => local_mode, :source => @destination_dir })
        publish :update_unit_date_queued_for_ingest, message
        on_success "Unit #{@unit_id} has been successfully copied to both the DL and patron process directories"
      else
        on_error "Unknown @mode passed to copy_unit_for_deliverable_generation_processor"
      end
      # If a unit has not already been archived (i.e. this unit did not arrive at this processor from start_ingest_from_archive) archive it.
      if not @working_unit.date_archived
        on_success "Because this unit has not already been archived, it is being sent to the archive."
        message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :internal_dir => 'yes', :source_dir => IN_PROCESS_DIR })
        publish :send_unit_to_archive, message
      end
    else
      @failure_messages.each {|message|
        on_failure "#{message}"
      }
      on_error "There were failures in the copying process."
    end
  end
end
