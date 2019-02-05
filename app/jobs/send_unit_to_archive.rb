class SendUnitToArchive < BaseJob

   require 'digest/md5'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      unit = Unit.find(message[:unit_id])
      unit_dir = "%09d" % unit.id

      if unit.throw_away
         logger.info "This unit has been flagged as a throw-away scan and will not be set to the archive."
         src_dir =  Finder.finalization_dir(unit, :in_process)
         MoveCompletedDirectoryToDeleteDirectory.exec_now({ unit_id: unit.id, source_dir: src_dir}, self)
         return
      end

      in_proc = Finder.finalization_dir(unit, :in_process)
      unit_dir = File.basename in_proc
      unit_archive_dir = File.join(ARCHIVE_DIR, unit_dir)
      FileUtils.makedirs(unit_archive_dir)
      FileUtils.chmod(0775, unit_archive_dir)
      errors = 0

      Dir.glob(File.join(in_proc, "**/*")).each do |f|
         # if we run into any subdirs here, it is becase teh source files
         # were nested to indicate location info. This hs been captured in location metadata
         # and is no longer required. Flatten.
         next if File.directory? f

         filename = File.basename f
         archive_file = File.join(unit_archive_dir, filename)
         FileUtils.copy(f, archive_file)
         FileUtils.chmod(0664, archive_file)

         src_md5 = Digest::MD5.hexdigest(File.read(f) )
         dest_md5 = Digest::MD5.hexdigest(File.read(archive_file) )

         if src_md5 != dest_md5
            log_failure("** Warning ** - File #{f} has failed checksum test")
            errors += 1
         else
            mf = MasterFile.find_by(filename: filename)
            if !mf.nil?
               mf.update(md5: src_md5, date_archived: Time.now)
            end
         end
      end

      if errors == 0
         logger.info "The directory #{unit_dir} has been successfully archived."
         unit.update(date_archived: Time.now)
         logger.info "Date Archived set to #{unit.date_archived} for for unit #{unit.id}"

         # See if all units in the parent order are complete. Flag date if so
         check_order_archive_complete(unit.order)

         # Now that all archiving work for the unit is done,
         # it (and any subsidary files) must be moved to the ready_to_delete directory
         src_dir =  Finder.finalization_dir(unit, :in_process)
         MoveCompletedDirectoryToDeleteDirectory.exec_now({ unit_id: unit.id, source_dir: src_dir}, self)
      else
         fatal_error "There were errors with the archiving process"
      end
   end

   private
   def check_order_archive_complete(order)
      logger.info "Checking if all units in order #{order.id} are complete..."
      incomplete_units = Array.new
      order.units.each do |unit|
         # If an order can have both patron and dl-only units (i.e. some units have an intended use of "Digital Collection Building")
         # then we have to remove from consideration those units whose intended use is "Digital Collection Building"
         # and consider all other units.
         if unit.unit_status != "canceled"
            if unit.date_archived.blank?
               incomplete_units.push(unit.id)
            end
         end
      end

      if incomplete_units.empty?
         # The 'patron' units within the order are complete
         order.update_attribute(:date_archiving_complete, Time.now)
         logger.info "All units in order #{order.id} are archived."
      else
         # Order incomplete.  List units incomplete units in message
         logger.info "Order #{order.id} has some units (#{incomplete_units.join(', ')}) that have not been archived."
      end
   end
end
