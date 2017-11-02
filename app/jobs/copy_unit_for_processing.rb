class CopyUnitForProcessing < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   # After this step, all masterfiles for the unit will reside in PROCESSING and be flat (no subdirs)
   def do_workflow(message)
      unit = message[:unit]
      in_proc_dir = Finder.finalization_dir(unit, :in_process)
      destination_dir = Finder.finalization_dir(unit, :process_deliverables)
      FileUtils.mkdir_p(destination_dir)

      # copy all of the master files for this unit to the processing directory
      logger.debug("Copying all master files from #{in_proc_dir} to #{destination_dir}")
      unit.master_files.each do |master_file|
         # find the masterfile src file wherever it may reside in subdirectories
         full_src_path = Dir.glob(File.join(in_proc_dir, "**", master_file.filename)).first

         begin
            # FLATTEN directories: copy all MF to same level in dest dir (remove subdirs if they were present)
            FileUtils.cp(full_src_path, File.join(destination_dir, master_file.filename))
         rescue Exception => e
            on_error "Can't copy source file '#{master_file.filename}': #{e.message}"
         end

         # compare MD5 checksums
         source_md5 = Digest::MD5.hexdigest(File.read(full_src_path))
         dest_md5 = Digest::MD5.hexdigest(File.read(File.join(destination_dir, master_file.filename)))
         if source_md5 != dest_md5
            on_error "Failed to copy source file '#{master_file.filename}': MD5 checksums do not match"
         end
      end
   end
end
