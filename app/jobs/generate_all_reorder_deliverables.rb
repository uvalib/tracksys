class GenerateAllReorderDeliverables < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Order", :originator_id=>message[:order_id] )
   end

   def copy_master_files(unit, source_dir, destination_dir)
      logger.debug("Copying all master files from #{source_dir} to #{destination_dir}")
      unit.master_files.each do |master_file|
         begin
            FileUtils.cp(File.join(source_dir, master_file.filename), File.join(destination_dir, master_file.filename))
         rescue Exception => e
            on_error "Can't copy source file '#{master_file.filename}': #{e.message}"
         end

         # compare MD5 checksums
         source_md5 = Digest::MD5.hexdigest(File.read(File.join(source_dir, master_file.filename)))
         dest_md5 = Digest::MD5.hexdigest(File.read(File.join(destination_dir, master_file.filename)))
         if source_md5 != dest_md5
            on_error "Failed to copy source file '#{master_file.filename}': MD5 checksums do not match"
         end
      end
      logger.debug("All master files copied")
   end

   def do_workflow(message)
      raise "Parameter 'order_id' is required" if message[:order_id].blank?
      order = Order.find(message[:order_id])

      order.units.each do |unit|
         source_dir = Finder.finalization_dir(unit, :in_process)
         destination_dir =  Finder.finalization_dir(unit, :process_deliverables)
         FileUtils.mkdir_p(destination_dir)

         copy_master_files(unit, source_dir, destination_dir)
         QueuePatronDeliverables.exec_now({ :unit => unit, :source => destination_dir }, self)
         CreateUnitZip.exec_now( { unit: unit }, self)
         MoveCompletedDirectoryToDeleteDirectory.exec_now({ :unit_id => unit.id, :source_dir => Finder.finalization_dir(unit, :in_process)}, self)
      end

      CheckOrderReadyForDelivery.exec_now( { :order_id => order.id}, self  )
   end
end
