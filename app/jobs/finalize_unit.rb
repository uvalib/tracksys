class FinalizeUnit < BaseJob
   require 'fileutils'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      unit =  Unit.find( message[:unit_id] )

      # Almost all units will be associated with a project.
      # Finalizing raw images is a special case. It occurs outside of the normal
      # digitization workflow and will not have a project. Handle this.
      src_dir = Finder.finalization_dir(unit, :dropoff)
      in_process_dir = Finder.finalization_dir(unit, :in_process)
      if !unit.project.nil?
         @project = unit.project
         logger().info "Project #{@project.id}, unit #{unit.id} begins finalization."
      else
         logger().info "Unit #{unit.id} begins finalization without project."
      end

      if !Dir.exists? src_dir
         fatal_error("Dropoff directory #{src_dir} does not exist")
      end

      logger().info "Moving unit #{unit.id} from #{src_dir} to #{in_process_dir}"
      FileUtils.mv(src_dir, in_process_dir)
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
         logger().fatal "Unit #{@project.unit.id} failed Finalization"
         @project.finalization_failure( status_object() )
      end
   end
end
