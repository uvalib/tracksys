class CopyDirectoryFromArchiveProcessor < ApplicationProcessor

  subscribes_to :copy_directory_from_archive, {:ack=>'client', 'activemq.prefetchSize' => 1}

  def on_message(message)
    logger.debug "CopyDirectoryFromArchive received: " + message.to_s

    # There are two kinds of messages sent to this processor:
    # 1. Download one master file
    # 2. Download all master files for a unit
    # All messages will include a unit_id.

    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    raise "Parameter 'path_to_archive' is required" if hash[:path_to_archive].blank?
    @unit_id = hash[:unit_id]
    @unit_dir = "%09d" % @unit_id
    @working_unit = Unit.find(@unit_id)
    @messagable_id = hash[:unit_id]
    @messagable_type = "Unit"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)
    @failure_messages = Array.new
    @source_dir = hash[:path_to_archive]
    @destination_dir = File.join('/lib_content37/stornext_dropoff', @unit_dir)
    FileUtils.mkdir_p(@destination_dir)

    # glob filenames from old directory
    @file_list = Dir.glob("#{@source_dir}/[^.]*.tif").sort!
    @master_files = @working_unit.master_files
    unless  @master_files.length == @file_list.length then raise ArgumentError end
    @master_files.each_index do |i|
      oldfn = @file_list[i].to_s
      newfn = @master_files[i].filename.to_s
      FileUtils.cp(oldfn, File.join(@destination_dir, newfn))
      # compare MD5 checksums
      source_md5 = Digest::MD5.hexdigest(File.read(oldfn))
      dest_md5 = Digest::MD5.hexdigest(File.read(File.join(@destination_dir, newfn)))
      if source_md5 != dest_md5
        @failure_messages << "Error in copy operation: source file '#{oldfn}' to '#{newfn}': MD5 checksums do not match"
      end
    end

    if @failure_messages.empty?
        on_success "All master files from unit #{@unit_id} have been successfully copied to #{@destination_dir}."

        # Negate the @unit_id variable so the following AutomationMessage is not associated with the Unit
        @unit_id = nil
        @last_master_file = @master_files.last
        @master_files.each {|mf|
          if mf == @last_master_file
            @last = 1
          else
            @last = 0
          end
          @master_file_id = mf.id
          message = { :master_file_id => @master_file_id, :source => @destination_dir, :last => @last }
          CreateImageTechnicalMetadataAndThumbnail.exec( message )
          on_success "Now creating the technical metadata for MasterFile #{@master_file_id}."
        }
    else
      @failure_messages.each {|message|
        on_failure "#{message}"
      }
      on_error "There were failures in the copying process."
    end
  end
end
