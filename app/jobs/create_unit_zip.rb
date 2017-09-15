class CreateUnitZip < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id)
   end

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      unit = message[:unit]
      order = unit.order

      # Make sure order delivery dir exists
      delivery_dir = File.join("#{DELIVERY_DIR}", "order_#{order.id}")
      FileUtils.mkdir_p delivery_dir if !Dir.exist?(delivery_dir)

      # generate first zip file name, and fail if it already exists
      file_num = 1
      zip_file = File.join(delivery_dir, "#{unit.id}_#{file_num}.zip")
      if File.exist? zip_file
         if message[:replace]
            logger.info "Removing pre-existing zip deliverables"
            Dir.glob("#{delivery_dir}#{unit.id}_*.zip/") { |z| File.delete z }
         else
            on_error "A .zip archive for unit #{unit.id} already exists."
         end
      end

      # unit_path is the path to the unit tif/jpg files
      unit_path = Finder.finalization_dir(unit, :assemble_deliverables)

      # The zip file is stored one directory level down in the order dir
      zip_order_path = unit_path.split('/')[0...-1].join('/')

      # Walk each file in the unit assembly dir and add it to the zip...
      Dir.foreach(unit_path) do |f|
         next if f == '.' || f == '..' || f == '.DS_Store' || f == '.AppleDouble'

         # build the zip command. cd to the order directory first so
         # unzip will generate only a unit directory
         zip_cmd = "cd #{zip_order_path}; zip #{zip_file} #{File.join(unit.id.to_s, f)}"
         `#{zip_cmd}`

         # if the zip is now too big, start another
         if (File.size(zip_file).to_f / 1024.0**3).to_i > Settings.zip_max_gb.to_i
            file_num += 1
            zip_file = File.join(delivery_dir, "#{unit.id}_#{file_num}.zip")
         end
      end

      on_success "Unit #{unit.id} zipped into #{file_num} zip archive(s)."
   end
end
