class QaFilesystem < BaseJob
   require 'nokogiri'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      # Set unit variables
      @unit = Unit.find(message[:unit_id])
      @unit_dir = "%09d" % @unit.id
      @in_proc_dir = Finder.finalization_dir(@unit, :in_process)

      # Create error message holder array
      @error_messages = Array.new

      # Create a series of arrays to hold the files contained within the entry directory so that each type
      # of expected and unexpected files can be tested for compliance.
      @tif_files = Array.new
      @unknown_files = Array.new

      # recurse through all files/directories in the unit inprocess directory
      # NOTE: the final step of the project automation ensures that no garbage files
      # get through to this stage. Most of the original filtering code that was
      # present here is no longer needed (see Step::validate_last_step_dir )
      Dir.glob(File.join(@in_proc_dir, "**/*")).each do |dir_entry|
         next if File.directory? dir_entry  # skip the directory names
         if (dir_entry =~ /.tif$/)
            @tif_files.push(dir_entry)
         elsif (dir_entry !~ /.txt$/)    # safe to ignore (.txt files are OCR data typically)
            @unknown_files.push(dir_entry)
         end
      end

      #NOTE: when using the .glob call above, all files in the lists will be FULL PATH
      check_tif_files
      check_unknown_files
      handle_errors
   end

   def check_tif_files
      logger.info "Check content files..."
      # Checking for:
      # 1. Existence of TIF files.
      # 2. The number of content files in the directory equals the sequence number of the last file.
      # 3. All TIF files conform to the naming convention.
      # 4. No file is less than 1MB (1MB being a size arbitrarily determined to represent a "too small" file)
      minimum_size=2048

      if @tif_files.empty?
         @error_messages.push("There are no .tif files in the directory.")
         return
      end

      # Check that the number of .tif files in the entry directory equals the sequence number of the last file
      @tif_files.sort!
      @number_tif_files = @tif_files.length

      # Define regex to ensure the file ends with an _, followed by four digits followed by .tif
      regex_content_file = Regexp.new('_\d{4}.(tif)$')

      max_sequence_num = -1
      max_seq_file = ""
      @tif_files.each do |content_file_path|
         content_file = File.basename(content_file_path)

         # extract the sequence num from the name: unit_SEQ.tif
         seq = content_file.split("_")[1].split(".")[0].to_i
         if seq > max_sequence_num
            max_sequence_num = seq
            max_seq_file = content_file
         end

         # Check that the content file begins with the unit number
         if content_file !~ /^#{@unit_dir}/
            @error_messages.push("#{content_file} does not start with the correct unit #{@unit_dir}")
         end
         # Check the file part of the tif file
         if regex_content_file.match(content_file).nil?
            @error_messages.push("#{content_file} has an incorrectly formatted sequence number or extension.")
         end
         # Check that the content file is greater than 1MB.
         if File.size(content_file_path) < minimum_size
            @error_messages.push("#{content_file} is less than #{minimum_size} bytes large and is very likely an incorrect file.")
         end
      end

      if max_sequence_num > @number_tif_files
         @error_messages.push("The number of tif files in directory (#{@number_tif_files}) does not equal the sequence number of the last file (#{max_seq_file}).")
      end
   end

   def check_unknown_files
      logger.info "Check unknown files..."
      @unknown_files.each do |unknown_file|
         @error_messages.push("Contains unexpected or non-standard file: #{File.basename(unknown_file)}.")
      end
   end

   def handle_errors
      logger.info "Handle Errors: [#{@error_messages.join(', ')}]"
      if @error_messages.empty?
         logger.info "Unit #{@unit.id} has passed the Filesystem QA"
         ImportUnitImages.exec_now({ :unit_id => @unit.id }, self)
      else
         @error_messages.each do |message|
            log_failure message
         end
         fatal_error "Unit #{@unit.id} has failed the Filesystem QA."
      end
   end
end
