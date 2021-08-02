module Archive

   require 'digest/md5'

   def self.publish(unit, logger = Logger.new(STDOUT))
      if unit.throw_away || unit.reorder
         logger.info "This unit has been flagged is a reorder or a throw-away scan. It will not be sent to the archive."
         return
      end

      unit_dir = "%09d" % unit.id
      src_dir = File.join(Settings.production_mount, "finalization", unit_dir)
      unit_archive_dir = File.join(ARCHIVE_DIR, unit_dir)
      logger.info "Archive #{src_dir} to #{unit_archive_dir}"
      FileUtils.makedirs(unit_archive_dir)
      FileUtils.chmod(0775, unit_archive_dir)
      errors = 0

      Dir.glob(File.join(src_dir, "**/*")).sort.each do |f|
         # if we run into any subdirs here, it is becase teh source files
         # were nested to indicate location info. This hs been captured in location metadata
         # and is no longer required. Flatten.
         next if File.directory? f

         filename = File.basename f
         archive_file = File.join(unit_archive_dir, filename)
         FileUtils.copy(f, archive_file)
         FileUtils.chmod(0664, archive_file)
         logger.info "Archived #{f} to #{archive_file}"

         src_md5 = Digest::MD5.hexdigest(File.read(f) )
         dest_md5 = Digest::MD5.hexdigest(File.read(archive_file) )

         if src_md5 != dest_md5
            logger.error("File #{f} has failed checksum test")
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
         Archive.check_order_archive_complete(unit.order, logger)
      else
         raise "There were errors with the archiving process"
      end
   end

   def self.check_order_archive_complete(order, logger)
      logger.info "Checking if all units in order #{order.id} are complete..."
      has_incomplete = false
      order.units.each do |unit|
         if unit.unit_status != "canceled"
            if unit.date_archived.blank?
               has_incomplete = true
               break
            end
         end
      end

      if has_incomplete == false
         order.update_attribute(:date_archiving_complete, Time.now)
         logger.info "All units in order #{order.id} are archived."
      end
   end
end
