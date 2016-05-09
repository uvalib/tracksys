class QueueUnitDeliverables < BaseJob

   def do_workflow(message)

      # Validate incoming messages
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'source' is required" if message[:source].blank?

      unit = message[:unit]
      master_files = unit.master_files
      source = message[:source]

      # Get unit level deliverable information (formation, resolution and customer status)
      remove_watermark = unit.remove_watermark
      fmt = unit.intended_use_deliverable_format
      desired_resolution = unit.intended_use_deliverable_resolution
      personal_item = unit.bibl.personal_item?
      call_number = unit.bibl.call_number
      title = unit.bibl.title
      location = unit.bibl.location

      master_files.each do |master_file|
         if master_file == master_files.last
            last = "1"
         else
            last = "0"
         end

         # Ensure that master file has a pid
         if not master_file.pid
            master_file.pid = AssignPids.get_pid
            master_file.save!
         end

         actual_resolution = master_file.image_tech_meta.resolution
         file_source = File.join(source, master_file.filename)

         CreatePatronDeliverables.exec_now({ :master_file_id => master_file.id, :source => file_source,
            :format => fmt, :actual_resolution => actual_resolution,
            :desired_resolution => desired_resolution, :unit_id => unit.id, :last => last,
            :personal_item => personal_item, :call_number => call_number, :title => title,
            :location => location, :remove_watermark => remove_watermark}, self)
      end
   end
end
