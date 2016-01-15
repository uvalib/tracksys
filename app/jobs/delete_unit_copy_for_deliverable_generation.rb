class DeleteUnitCopyForDeliverableGeneration < BaseJob

   def perform(message)
      Job_Log.debug "DeleteUnitCopyForDeliverableGenerationProcessor received: #{message.to_json}"

      @mode = message[:mode]
      @unit_id = message[:unit_id]
      @messagable_id = message[:unit_id]
      @messagable_type = "Unit"
      set_workflow_type()
      @unit_dir = "%09d" % @unit_id
      order_id = Unit.find(@unit_id).order.id

      # Delete logic
      FileUtils.rm_rf(File.join(PROCESS_DELIVERABLES_DIR, @mode, @unit_dir))

      # Send messages
      if @mode == 'patron'
         msg = { :order_id => order_id, :unit_id => @unit_id })
         UpdateUnitDatePatronDeliverablesReady.exec_now(msg)
         CheckOrderReadyForDelivery.exec_now(msg)
      end
      on_success "Files for unit #{@unit_id} copied for the creation of #{@dl} deliverables have now been deleted."
   end
end
