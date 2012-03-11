class CopyMetadataToMetadataDirectoryProcessor < ApplicationProcessor

  subscribes_to :copy_metadata_to_metadata_directory, {:ack=>'client', 'activemq.prefetchSize' => 1}

  def on_message(message)
    logger.debug "CopyMetadataToMetadataDirectoryProcessor received: " + message.to_s

    hash = ActiveSupport::JSON.decode(message).symbolize_keys 
    
    # Validate incoming message
    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    raise "Parameter 'unit_path' is required" if hash[:unit_path].blank?
       
    @unit_id = hash[:unit_id]  
    @messagable = Unit.find(@unit_id)
    @unit_dir = "%09d" % @unit_id
    @unit_path = hash[:unit_path]
    @failure_messages = Array.new

    # Get the contents of /digiserv-production/metadata and exclude directories that don't begin with and end with a number.  Hopefully this
    # will eliminate other directories that are of non-Tracksys managed content.
    @metadata_dir_contents = Dir.entries(PRODUCTION_METADATA_DIR).delete_if {|x| x == '.' or x == '..' or not /^[0-9](.*)[0-9]$/ =~ x}
    @metadata_dir_contents.each {|dir|
      @range = dir.split('-')
      if @unit_id.to_i.between?(@range.first.to_i, @range.last.to_i)
        @range_dir = dir
      end
    }
    
    if not @range_dir
      on_error "No subdirectories of #{PRODUCTION_METADATA_DIR} appear to be suitable for #{@unit_id}.  Please create a directory in the format 'dddd-dddd' to house the metadata for this unit."
    end

    @destination_dir = File.join(PRODUCTION_METADATA_DIR,  @range_dir, @unit_dir)

    if File.exist?(@destination_dir)
      on_failure "The metadata for unit #{@unit_id} already exists in #{PRODUCTION_METADATA_DIR}/#{@range_dir}.  The directory will be deleted and a new one created in its place.."
      FileUtils.rm_rf(@destination_dir)
      FileUtils.mkdir_p(@destination_dir)
    else
      FileUtils.mkdir_p(@destination_dir)
    end

    @unit_dir_contents = Dir.entries(@unit_path).delete_if {|x| x == '.' or x == '..' or /.tif/ =~ x}
    @unit_dir_contents.each {|content|
      begin
        if File.directory?(File.join(@unit_path, content))
          if /Thumbnails/ =~ content
            FileUtils.cp_r(File.join(@unit_path, content), File.join(@destination_dir, content))
          else
            @failure_messages << "Unknown directory in #{@unit_dir}" 
          end
        else
          FileUtils.cp(File.join(@unit_path, content), File.join(@destination_dir, content))

          # compare MD5 checksums
          source_md5 = Digest::MD5.hexdigest(File.read(File.join(@unit_path, content)))
          dest_md5 = Digest::MD5.hexdigest(File.read(File.join(@destination_dir, content)))
          if source_md5 != dest_md5
            @failure_messages << "Failed to copy source file '#{master_file.filename}': MD5 checksums do not match"
          end
        end
       rescue Exception => e
         @failure_messages << "Can't copy source file '#{content}': #{e.message}"
      end
    }

    if @failure_messages.empty?
      on_success "Unit #{@unit_id} metadata files have been successfully copied  to #{@destination_dir}."
    else
      @failure_messages.each {|message|
        on_failure "#{message}"
      }
      on_error "There were failures copying files to #{PRODUCTION_METADATA_DIR}."
    end
  end
end
