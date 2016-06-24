class FlagForPublication < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=> message[:object].class.name, :originator_id=>message[:object].id)
   end

   def do_workflow(message)
      object = message[:object]

      if object.is_a? Unit
         flag_unit_for_publication(object)
      elsif object.is_a? MasterFile
         flag_master_file_for_publication(object)
      elsif object.is_a? Bibl
         flag_bibl_for_publication(object)
      elsif object.is_a? Component
         flag_component_for_publication(object)
      else
         on_error "Object #{object_class} #{object_id} is not supported."
      end
   end

   def flag_unit_for_publication(unit)
      now = Time.now
      unit.bibl.update_attribute(:date_dl_update, now)
      unit.master_files.each do |mf|
         mf.update_attribute(:date_dl_update, now)
      end
      logger.info "Unit #{unit.id} and #{unit.master_files.count} master files have been flagged for an update in the DL"
   end

   def flag_master_file_for_publication(mf)
      mf.update_attribute(:date_dl_update, Time.now)
      logger.info "Master File #{mf.id} has been flagged for an update in the DL"
   end

   def flag_bibl_for_publication(bibl)
      bibl.update_attribute(:date_dl_update, Time.now)
      bibl.master_files.each do |mf|
         mf.update_attribute(:date_dl_update, now)
      end
      logger.info "Bibl #{bibl.id} has been flagged for an update in the DL"
   end

   def flag_component_for_publication(component)
      component.update_attribute(:date_dl_update, Time.now)
      logger.info "Component #{component.id} has been flagged for an update in the DL"
   end
end
