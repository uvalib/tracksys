class CopyArchivedFilesToProductionProcessor < ApplicationProcessor

  subscribes_to :copy_archived_files_to_production, {:ack=>'client', 'activemq.prefetchSize' => 1}

  def on_message(message)
    logger.debug "CopyArchivedFilesToProductionProcessor received: " + message.to_s

    # There are two kinds of messages sent to this processor:
    # 1. Download one master file
    # 2. Download all master files for a unit
    # All messages will include a unit_id.

    hash = ActiveSupport::JSON.decode(message).symbolize_keys 

    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    raise "Parameter 'computing_id' is required" if hash[:computing_id].blank?
    @unit_id = hash[:unit_id] 
    @unit_dir = "%09d" % @unit_id
    @working_unit = Unit.find(@unit_id)
    @messagable_id = hash[:unit_id]
    @messagable_type = "Unit"
    @failure_messages = Array.new
    @source_dir = File.join(ARCHIVE_READ_DIR, @unit_dir)
    @destination_dir = File.join(PRODUCTION_SCAN_FROM_ARCHIVE_DIR, hash[:computing_id])
    FileUtils.mkdir_p(@destination_dir)

    if hash[:master_file_filename]
      master_file_filename = hash[:master_file_filename]
      begin
        FileUtils.cp(File.join(@source_dir, master_file_filename), File.join(@destination_dir, master_file_filename))
      rescue Exception => e
        @failure_messages << "Can't copy source file '#{master_file_filename}': #{e.message}"
      end

      # compare MD5 checksums
      source_md5 = Digest::MD5.hexdigest(File.read(File.join(@source_dir, master_file_filename)))
      dest_md5 = Digest::MD5.hexdigest(File.read(File.join(@destination_dir, master_file_filename)))
      if source_md5 != dest_md5
        @failure_messages << "Failed to copy source file '#{master_file_filename}': MD5 checksums do not match"
      end
    else
      @master_files = @working_unit.master_files
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
      if File.exist?(File.join(@source_dir, "#{@unit_dir}.ivc"))
       	FileUtils.cp(File.join(@source_dir, "#{@unit_dir}.ivc"), File.join(@destination_dir, "#{@unit_dir}.ivc"))
      end
    end

    if @failure_messages.empty?
      if master_file_filename
        on_success "Master file #{master_file_filename} from unit #{@unit_id} has been successfully copied to #{@destination_dir}."
      else
        on_success "All master files from unit #{@unit_id} have been successfully copied to #{@destination_dir}."
      end
    else
      @failure_messages.each {|message|
        on_failure "#{message}"
      }
      on_error "There were failures in the copying process."
    end
  end
end
