module Archive

   require 'digest/md5'

   def self.publish(mf_path, master_file, logger = Logger.new(STDOUT))
      if master_file.unit.throw_away || master_file.unit.reorder
         logger.info "This unit has been flagged is a reorder or a throw-away scan. It will not be sent to the archive."
         return
      end

      unit_dir = master_file.unit.directory
      unit_archive_dir = File.join(ARCHIVE_DIR, unit_dir)
      logger.info "Archive #{mf_path} to #{unit_archive_dir}"
      FileUtils.makedirs(unit_archive_dir)
      FileUtils.chmod(0775, unit_archive_dir)

      archive_file = File.join(unit_archive_dir,  master_file.filename)
      FileUtils.copy(mf_path, archive_file)
      FileUtils.chmod(0664, archive_file)
      logger.info "Archived #{mf_path} to #{archive_file}"

      src_md5 = Digest::MD5.hexdigest(File.read(mf_path) )
      dest_md5 = Digest::MD5.hexdigest(File.read(archive_file) )

      if src_md5 != dest_md5
         raise "File #{mf_path} has failed checksum test"
      end

      master_file.update(md5: src_md5, date_archived: Time.now)
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
