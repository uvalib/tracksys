class CopyMetadataToMetadataDirectory < BaseJob

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'unit_path' is required" if message[:unit_path].blank?

      unit_id = message[:unit_id]
      unit_dir = "%09d" % unit_id
      unit_path = message[:unit_path] # IN_PROCESS_DIR/unit
      failure_messages = Array.new

      # See if the metadata range dir exists. Create it if not.
      min_range = unit_id / 1000 * 1000  # round unit to thousands
      max_range = min_range + 999        # add 999 for a 1000 span range, like 33000-33999
      range_sub_dir = "#{min_range}-#{max_range}"
      range_dir = File.join(PRODUCTION_METADATA_DIR, range_sub_dir)
      if !Dir.exists?(range_dir)
         logger().info "Metadata range dir #{range_dir} does not exist. Creating now."
         FileUtils.mkdir_p(range_dir)
      end

      # tack the unit dir to this range. this is where metadata will be stored
      destination_dir = File.join(range_dir, unit_dir)
      logger().debug "Metadata SRC: #{unit_path} => DEST #{destination_dir }"
      if File.exist?(destination_dir)
         on_failure "The metadata for unit #{unit_id} already exists in #{destination_dir}.  The directory will be deleted and a new one created in its place.."
         FileUtils.rm_rf(destination_dir)
         FileUtils.mkdir_p(destination_dir)
      else
         FileUtils.mkdir_p(destination_dir)
      end

      unit_dir_contents = Dir.entries(unit_path).delete_if {|x| x == '.' or x == '..' or /.tif/ =~ x}
      unit_dir_contents.each do |content|
         begin
            if File.directory?(File.join(unit_path, content))
               if /Thumbnails/ =~ content
                  FileUtils.cp_r(File.join(unit_path, content), File.join(destination_dir, content))
               elsif content == ".AppleDouble"  # ignore .AppleDouble for now
               else
                  failure_messages << "Unknown directory in #{unit_dir}"
               end
            else
               FileUtils.cp(File.join(unit_path, content), File.join(destination_dir, content))

               # compare MD5 checksums
               source_md5 = Digest::MD5.hexdigest(File.read(File.join(unit_path, content)))
               dest_md5 = Digest::MD5.hexdigest(File.read(File.join(destination_dir, content)))
               if source_md5 != dest_md5
                  failure_messages << "Failed to copy source file '#{master_file.filename}': MD5 checksums do not match"
               end
            end
         rescue Exception => e
            failure_messages << "Can't copy source file '#{content}': #{e.message}"
         end
      end

      if failure_messages.empty?
         on_success "Unit #{unit_id} metadata files have been successfully copied  to #{destination_dir}."
      else
         failure_messages.each do |message|
            on_failure "#{message}"
         end
         on_error "There were failures copying files to #{PRODUCTION_METADATA_DIR}."
      end
   end
end
