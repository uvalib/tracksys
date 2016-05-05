class DeleteUnitCopyForDeliverableGeneration < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)

      @mode = message[:mode]
      @unit_id = message[:unit_id]
      @unit_dir = "%09d" % @unit_id
      @working_unit = Unit.find(@unit_id)
      order = @working_unit.order

      # Delete logic
      del_dir = File.join(PROCESS_DELIVERABLES_DIR, @mode, @unit_dir)
      logger().info("Removing processing directory #{del_dir}/...")
      FileUtils.rm_rf(del_dir)
      on_success "Files for unit #{@unit_id} copied for the creation of #{@dl} deliverables have now been deleted."

      # Send messages
      if @mode == 'patron'
         @working_unit.update_attribute(:date_patron_deliverables_ready, Time.now)
         on_success "Date patron deliverables ready for unit #{@unit_id} has been updated."

         CheckOrderReadyForDelivery.exec_now( { :order => order, :unit_id => @unit_id }, self  )
      end
   end
end
