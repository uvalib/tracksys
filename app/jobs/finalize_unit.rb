class FinalizeUnit < BaseJob
   require 'fileutils'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      unit =  Unit.find( message[:unit_id] )

      # Project is an optional param for finailizations that begin
      # from a project (the majority). Finalizing raw images is a special
      # case. It occurs outside of the normal digitization workflow and
      # will not have a project
      if !message[:project_id].nil?
         @project = Project.find(message[:project_id])
         logger().info "Project #{@project.id}, unit #{unit.id} begins finalization."

      else
         logger().info "Unit #{unit.id} begins dinalization."
      end

      src_dir = File.join(FINALIZATION_DROPOFF_DIR_PRODUCTION, unit.directory)
      if !Dir.exists? src_dir
         on_error("Dropoff directory #{src_dir} does not exist")
      end

      logger().info "Moving unit #{unit.id} from dropoff to #{src_dir}"
      FileUtils.mv(src_dir, File.join(IN_PROCESS_DIR, unit.directory))
      QaUnitData.exec_now( { :unit_id => unit.id }, self)

      # At this point, finalization has completed successfully and project is done
      if !@project.nil?
         @project.finalization_success( status_object() )
      end
   end

   # Override the normal delayed_job failure hook to pass the
   # problem info back to the project
   def failure(job)
      if !@project.nil?
         logger().info "Unit #{@project.unit.id} failed Finalization; updating project #{@project.id} with failure info"
         @project.finalization_failure( status_object() )
      end
      super
   end
end
