class RenumberMasterFiles < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'filenames' is required" if message[:filenames].blank?
      raise "Parameter 'new_start_num' is required" if message[:new_start_num].blank?

      new_num = message[:new_start_num].to_i
      filenames = message[:filenames].sort
      tgt_fn = filenames.shift
      unit = Unit.find( message[:unit_id] )
      unit.master_files.each do |mf|
         if mf.filename == tgt_fn
            logger.info "MasterFile #{mf.filename} renumber from #{mf.title} to #{new_num}"
            mf.update(title: new_num)
            if filenames.empty?
               break
            else
               tgt_fn = filenames.shift
               new_num += 1
            end
         end
      end
   end
end
