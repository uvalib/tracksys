class FinalizeUnit < BaseJob
   require 'fileutils'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Project", :originator_id=>message[:project_id])
   end

   def do_workflow(message)
      raise "Parameter 'project_id' is required" if message[:project_id].blank?
      @project = Project.find(message[:project_id])

      logger().info "Unit #{@project.unit.id} begins Finalization."
      src_dir = File.join(FINALIZATION_DROPOFF_DIR_PRODUCTION, @project.unit.directory)
      if !Dir.exists? src_dir
         on_error("Dropoff directory #{src_dir} does not exist")
      end

      logger().info "Moving unit #{@project.unit.id} from dropoff to #{src_dir}"
      FileUtils.mv(src_dir, File.join(IN_PROCESS_DIR, @project.unit.directory))
      QaUnitData.exec_now( { :unit_id => @project.unit_id }, self)

      # At this point, finalization has completed successfully and project is done
      @project.finalization_success( status_object() )
   end

   # Override the normal delayed_job failure hook to pass the
   # problem info back to the project
   def failure(job)
      logger().info "Unit #{@project.unit.id} failed Finalization; updating project #{@project.id} with failure info"
      @project.finalization_failure( status_object() )
      super
   end
end
