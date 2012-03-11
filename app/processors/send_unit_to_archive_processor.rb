class SendUnitToArchiveProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :send_unit_to_archive, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :update_unit_archive_id
  publishes_to :move_completed_directory_to_delete_directory
  
  require 'find'
  #require 'ftools'
  require 'digest/md5'
  require 'pathname'
  
  def on_message(message)  
    logger.debug "SendUnitToArchiveProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys
    
    # Validate incoming message.
    raise "Parameter 'internal_dir' is required" if hash[:internal_dir].blank?
    raise "Parameter 'source_dir' is required" if hash[:source_dir].blank?

    @internal_dir = hash[:internal_dir]
    @source_dir = hash[:source_dir]

    # The next fork is whether the messages are coming from the start_manual processor or the regular finalization workflow

    # First, messages coming from the automated workflow
    if @source_dir == "#{IN_PROCESS_DIR}"
      raise "Parameter 'internal_dir' must equal 'yes' if 'source_dir' == #{@source_dir}" if not @internal_dir == 'yes'
      raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
      
      @unit_id = hash[:unit_id]
      @messagable = Unit.find(@unit_id)
      @unit_dir = "%09d" % @unit_id

    # Second, messages coming from the start_manual processor
    else
      if @internal_dir == 'yes'
        raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
        raise "Parameter 'unit_dir' is required" if hash[:unit_dir].blank?

        @unit_id = hash[:unit_id]
        @messagable = Unit.find(@unit_id)
        @unit_dir = hash[:unit_dir]     
      elsif @internal_dir == 'no'
        raise "Parameter 'unit_dir' is required" if hash[:unit_dir].blank?
        @unit_dir = hash[:unit_dir]     
      else
        on_error "Message to send_unit_to_archive_processor is incorrectly formatted.  Parameter 'internal_dir' is set to #{@internal_dir} but must equal either 'yes' or 'no'" 
      end
    end

    # Create array to hold all created directories so they can be removed after the process is complete
    created_dirs = Array.new
    @errors = 0
   
    Dir.chdir(@source_dir)
    
    Find.find(@unit_dir) do |f|
      case
      when File.file?(f)
        # Get pertinent information for creating dirs in REVIEW and DELETE dirs
        p = Pathname.new(f)
        parent = p.parent
        basename = p.basename

        # Ignore files that begin with .
        if /^\./ =~ p.basename
        else              
          File.copy(f, File.join(ARCHIVE_WRITE_DIR, parent, basename))
          File.chmod(0755, File.join(ARCHIVE_WRITE_DIR, parent, basename))
          # Calculate information for checksums
          source_md5 = Digest::MD5.hexdigest(File.read(f))
          copy_md5 = Digest::MD5.hexdigest(File.read(File.join(ARCHIVE_WRITE_DIR, parent, basename)))

          # Run checksum tests
          if copy_md5 != source_md5
            # Introduce logic here to move the entire unit directory to REVIEW_DIR, or 50_fail_checksum
            on_failure("** Warning ** - File #{f} has failed checksum test")
            @errors += 1         
          end
        end
      when File.directory?(f)
        File.makedirs(File.join(ARCHIVE_WRITE_DIR, f))
        File.chmod(0755, File.join(ARCHIVE_WRITE_DIR, f))
        created_dirs << f
      else 
        on_failure("Unknown file #{f} in #{parent}/#{basename}")
      end
    end

    if @errors.eql?(0)
      # If message originated from the finalization automation workflow, send a message to continue the unit (which has no deliverables) on the automated workflow.
      if @source_dir == "#{IN_PROCESS_DIR}"
        message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :source_dir => @source_dir})
        publish :update_unit_archive_id, message
        on_success "The directory #{@unit_dir} has been successfully uploaded to Stornext."
      end

      # If the unit is managed by TrackSys, more data must be updated.  Otherwise, nothing more can be done.
      if @source_dir != "#{IN_PROCESS_DIR}" and @internal_dir == 'yes'
        # Send message to update the 'archive' field in the Unit table.
        on_success "The directory #{@unit_dir} has been uploaded to StorNext and may be deleted."
        message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :source_dir => @source_dir})
        publish :update_unit_archive_id, message
      elsif @internal_dir == 'no'
        # If @internal_dir is 'no', no more information can be added to the tracking system and the item is ready for deletion.
        message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :source_dir => @source_dir, :unit_dir => @unit_dir})
        publish :move_completed_directory_to_delete_directory, message
        on_success "The directory #{@unit_dir} has been uploaded to StorNext and will now be moved to the #{DELETE_DIR_FROM_STORNEXT}."
      else
      end
    else
      on_error "There were errors with the archiving process"
    end
  end
end
