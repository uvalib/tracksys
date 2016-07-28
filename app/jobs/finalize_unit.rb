class FinalizeUnit < BaseJob
   require 'fileutils'

   def do_workflow(message)
      raise "Parameter 'user_id' is required" if message[:user_id].blank?
      raise "Parameter 'unit_dir' is required" if message[:unit_dir].blank?
      raise "Parameter 'finalization_dir' is required" if message[:finalization_dir].blank?

      finalization_dir =  message[:finalization_dir]
      unit_dir =  message[:unit_dir]

      logger().info "Directory #{unit_dir} begins the finalization workflow."
      FileUtils.mv File.join(finalization_dir, unit_dir), File.join(IN_PROCESS_DIR, unit_dir)
      unit_id = unit_dir.to_s.sub(/^0+/, '')
      unit = Unit.find(unit_id)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>unit_id )
      QaUnitData.exec_now( { :unit => unit }, self)

      # unit has been finalized. Now generate items
      GenerateItems.exec_now({ :unit => unit }, self)
   end
end
