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
         on_error("Dropoff directory #{src_dir} does not exist")
      end

      logger().info "Moving unit #{unit.id} from #{src_dir} to #{in_process_dir}"
      FileUtils.mv(src_dir, in_process_dir)
      QaUnitData.exec_now( { :unit_id => unit.id }, self)

      # The unit is done finalization. Now see if there needs to be a DigitalObject created
      # to represent it in ArchivesSpace...
      if unit.metadata.type == "ExternalMetadata" && unit.metadata.external_system == "ArchivesSpace"
         logger.info "Finalized unit has external ArchivesSpace metadata. See if a DigitalObject needs to be created..."
         auth = ArchivesSpace.get_auth_session()
         bits = unit.metadata.external_uri.split("/")
         obj = nil
         if bits[3] == "resources"
            logger.info "Look up ArchivesSpace object: #{unit.metadata.external_uri}"
            obj = ArchivesSpace.get_resource(auth, bits[2], bits[4])
         elsif bits[3] == "archival_objects"
            logger.info "Look up ArchivesSpace object: #{unit.metadata.external_uri}"
            obj = ArchivesSpace.get_archival_object(auth, bits[2], bits[4])
         else
            logger.info "External URI has unsupported parent type in URI: #{bits[3]}"
         end

         if !obj.nil?
            if ArchivesSpace.has_digital_object?(auth, obj, unit.metadata.pid) == false
               begin
                  logger.info "Creating digital object..."
                  ArchiveSpace.create_digital_object(auth, obj, unit.metadata, true)
                  logger.info "...success"
               rescue Exception=>e
                  logger.error "Unable to create ArchivesSpace digital object: #{e.message}"
               end
            else
               logger.info "ArchivesSpace already has a digital object for this item; nothing more to do."
            end
         end
      end

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
