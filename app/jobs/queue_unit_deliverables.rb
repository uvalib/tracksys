class QueueUnitDeliverables < BaseJob

   def perform(message)
      Job_Log.debug "QueueUnitDeliverablesProcessor received: #{message.to_json}"

      # Validate incoming messages
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'mode' is required" if message[:mode].blank?

      @unit_id = message[:unit_id]
      @mode = message[:mode]
      @source = message[:source]

      @unit_dir = "%09d" % @unit_id
      @working_unit = Unit.find(@unit_id)
      @messagable_id = message[:unit_id]
      @messagable_type = "Unit"
      set_workflow_type()
      @working_order = @working_unit.order
      @master_files = @working_unit.master_files

      # Get unit level deliverable information (formation, resolution and customer status)
      @remove_watermark = @working_unit.remove_watermark
      @format = @working_unit.intended_use_deliverable_format
      @desired_resolution = @working_unit.intended_use_deliverable_resolution
      @personal_item = @working_unit.bibl.personal_item?
      @call_number = @working_unit.bibl.call_number
      @title = @working_unit.bibl.title
      @location = @working_unit.bibl.location

      @master_files.each do |master_file|
         if master_file == @master_files.last
            @last = "1"
         else
            @last = "0"
         end

         # Ensure that master file has a pid
         if not master_file.pid
            master_file.pid = AssignPids.get_pid
            master_file.save!
         end

         @actual_resolution = master_file.image_tech_meta.resolution
         @file_source = File.join(@source, master_file.filename)

         CreatePatronDeliverables.exec_now({ :master_file_id => master_file.id, :source => @file_source, :mode => @mode, :format => @format, :actual_resolution => @actual_resolution, :desired_resolution => @desired_resolution, :unit_id => @unit_id, :last => @last, :personal_item => @personal_item, :call_number => @call_number, :title => @title, :location => @location, :remove_watermark => @remove_watermark})
      end
   end
end
