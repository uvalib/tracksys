class DeleteMasterFiles < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'filenames' is required" if message[:filenames].blank?

      unit = Unit.find(message[:unit_id])
      filenames = message[:filenames].sort

      fatal_error("Cannot delete from units that have been published") if unit.in_dl?

      archive_dir = File.join(ARCHIVE_DIR, unit.directory)

      # first remove all of the masterfiles from & tech metadata
      # the list from the unit, archive and IIIF server
      del_cnt = filenames.size
      del_fn = filenames.shift
      unit.master_files.each do |mf|
         if mf.filename == del_fn
            if !mf.is_clone?
               archive_file = File.join(archive_dir, del_fn)
               logger.info "Removing from archive: #{archive_file}"
               if File.exists? archive_file
                  FileUtils.rm(archive_file)
               else
                  log_failure "No archive found for #{del_fn}"
               end

               iiif_fn = mf.iiif_file()
               logger.info "Removing file published to IIIF: #{iiif_fn}"
               if File.exists? iiif_fn
                  FileUtils.rm(iiif_fn)
                  iiif_dir = File.dirname(iiif_fn)
                  if Dir.glob("#{iiif_dir}/*").empty?
                     FileUtils.rm_rf(iiif_dir)
                  end
               else
                  log_failure "No IIIF file found for #{del_fn}"
               end
            else
               cloned_file = File.join(Settings.production_mount, "finalization", unit.directory, mf.filename)
               if File.exist? cloned_file
                  logger.info "Removing cloned tif from in_process dir: #{cloned_file}"
                  File.delete(cloned_file)
               end
            end

            logger.info "Removing master file record #{del_fn}"
            mf.image_tech_meta.destroy if !mf.image_tech_meta.nil?
            mf.destroy

            del_fn = filenames.shift
            break if del_fn.nil?
         end
      end

      # Refresh the associated master files list to reflect the deletions above
      # without it, the loop below does nothing
      unit.master_files.reload

      cnt = unit.master_files_count
      logger.info "Updating unit master files count from #{cnt} to #{cnt-del_cnt}"
      unit.update(master_files_count: cnt-del_cnt)

      # next rename to fill gaps in page number
      logger.info "Updating remaining master files to correct page number gaps"
      prev_page = -1
      curr_page = 1
      sequential_titles = true
      unit.master_files.each do |mf|
         # if page titles are not a number, can't consider them to be sequential
         if mf.title.to_i.to_s != mf.title
            sequential_titles = false
         end
         if prev_page > -1 && prev_page+1 != curr_page
            sequential_titles = false
         end

         mf_pg = page_from_filename(mf.filename)
         if mf_pg > curr_page
            md5 = master_file_md5(mf)
            orig_fn = mf.filename
            pg_str = "%04d" % curr_page
            new_fn = "#{unit.directory}_#{pg_str}.tif"
            logger.info "Update MF filename from #{mf.filename} to #{new_fn}"
            mf.update(filename: new_fn)

            # see if the title is a number and that it is the different
            # from the new page number portion. If so, update it
            new_pg_num = page_from_filename(new_fn)
            if mf.title.to_i.to_s == mf.title && mf.title.to_i != new_pg_num && sequential_titles
               mf.update(title: curr_page.to_s)
            end

            if !mf.is_clone?
               archive_file = File.join(archive_dir, orig_fn)
               new_archive = File.join(archive_dir, new_fn)
               logger.info "Rename archived file #{archive_file} -> #{new_fn}"
               File.rename(archive_file, new_archive)
               new_md5 = Digest::MD5.hexdigest( File.read(new_archive) )
               fatal_error("MD5 does not match for rename #{archive_file} -> #{new_archive}") if new_md5 != md5
            else
               cloned_file = File.join(in_proc_dir, orig_fn)
               new_cloned_file = File.join(in_proc_dir, new_fn)
               logger.info "Rename cloned file #{cloned_file} -> #{new_cloned_file}"
               File.rename(cloned_file, new_cloned_file)
            end
         end

         prev_page = curr_page
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
