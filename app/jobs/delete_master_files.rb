class DeleteMasterFiles < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'filenames' is required" if message[:filenames].blank?

      unit = message[:unit]
      filenames = massage[:filenames].sort

      on_error("Cannot delete from units that have been published") if unit.in_dl?

      unit_dir = "%09d" % unit.id
      archive_dir = File.join(ARCHIVE_DIR, unit_dir)

      # first remove all of the masterfiles from & tech metadata
      # the list from the unit, archive and IIIF server
      del_fn = filenames.shift
      unit.master_files.each do |mf|
         if mf.filename == del_fn
            if !mf.is_clone?
               logger.info "Removing from archive"
               archive_file = File.join(archive_dir, del_fn)
               if File.exists? archive_file
                  FileUtils.rm(archive_file)
               else
                  on_failure "No archive found for #{del_fn}"
               end

               logger.info "Removing file published to IIIF"
               iiif_path = MasterFile.iiif_path(mf.pid)
               if File.exists? iiif_path
                  FileUtils.rm(iiif_path)
               else
                  on_failure "No IIIF file found for #{del_fn}"
               end
            end

            logger.info "Removing master file record #{del_fn}"
            mf.image_tech_meta.destroy
            mf.destroy

            del_fn = filenames.shift
            break if del_fn.nil?
         end
      end

      # next rename to fill gaps in page number
      logger.info "Updating remaining master files to correct page number gaps"
      curr_page = 1
      unit.master_files.each do |mf|
         mf_pg = page_from_filename(mf.filename)
         if mf_pg > curr
            md5 = master_file_md5(mf)
            orig_fn = mf.filename
            pg_str = "%04d" % curr_page
            new_fn = "#{unit_dir}_#{pg_str}.tif"
            mf.update(filename: new_fn)

            new_archive = File.join(archive_dir, new_fn)
            logger.info "Rename archived file #{archive_file} -> #{new_fn}"
            File.rename(archive_file, new_archive)
            new_md5 = Digest::MD5.hexdigest( File.read(new_archive) )
            on_error("MD5 does not match for rename #{archive_file} -> #{new_archive}") if new_md5 != md5
         end

         curr_page += 1
      end
   end

   def master_file_md5(mf)
      md5 = mf.md5
      if md5.blank?
         logger.info "Generating missing MD5"
         md5 = Digest::MD5.hexdigest(File.read(archive_file) )
         mf.update(md5: md5)
      end
      return md5
   end

   def page_from_filename(filename)
      pg_str = filename.split("_")[1].split(".")[0]
      return pg_str.to_i
   end
end
