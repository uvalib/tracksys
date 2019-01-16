class Api::ManifestController < ApplicationController
   # Get a JSON listing of all master files that belong to the specified
   # PID. The PID can be from a metadata record or component
   #
   def show
      pid = params[:pid]

      # First, determine type - Metadata, Component or Metadata with appolo reference
      obj = Metadata.find_by(pid: pid)
      if !obj.blank?
         out = get_metadata_manifest(obj, params[:unit])
         render json: JSON.pretty_generate(out)
         return
      end

      obj = Component.find_by(pid: pid)
      if !obj.blank?
         out = get_component_manifest(obj)
         render json: JSON.pretty_generate(out)
         return
      end

      render plain: "PID #{pid} was not found", status: :not_found
   end

   private
   def get_metadata_manifest(obj, unit_id)
      if !unit_id.nil?
   		logger.info("Only including masterfiles from unit #{unit_id}")
         files = obj.master_files.includes(:image_tech_meta).joins(:unit).where("units.id=?", unit_id).order(filename: :asc)
   	elsif obj.type == "ExternalMetadata" || !obj.supplemental_system.blank?
   		logger.info("This is External/supplemental metadata; including all master files")
         files = obj.master_files.includes(:image_tech_meta).joins(:unit).where("units.include_in_dl=1 or units.intended_use_id=110").order(filename: :asc)
         if files.count == 0
            # nothing found that was in DL or intended for DL. Just get all as fallback...
            files = obj.master_files.includes(:image_tech_meta).order(filename: :asc)
         end
   	else
   		logger.info("Only including masterfiles from units in the DL")
         files = obj.master_files.includes(:image_tech_meta).joins(:unit).where("units.include_in_dl=1").order(filename: :asc)
      end

      out  = []
      files.each do |mf|
         tech_meta = mf.image_tech_meta
         if tech_meta.nil?
            unit_dir = mf.filename.split("_")[0]
            archive_file = File.join(ARCHIVE_DIR, unit_dir, mf.filename)
            begin
               logger.warn("MasterFile #{mf.filename} is missing image tech metadata. Creating from #{archive_file}")
               tech_meta = TechMetadata.create(mf, archive_file)
            rescue Exception => e
               logger.error("Unable to create tech metadata: #{e}. Skipping.")
               next
            end
         end
         json = { id: mf.id, pid: mf.pid, filename: mf.filename, width: tech_meta.width, height: tech_meta.height }
         json[:title] = mf.title if !mf.title.nil?
         json[:description] = mf.description if !mf.description.nil?
         json[:exemplar] = mf.exemplar if mf.exemplar
         json[:text_source] = mf.text_source if !mf.text_source.nil?
         if !mf.original_mf_id.nil?
            orig = MasterFile.find(mf.original_mf_id)
            out[:cloned_from] = {id: orig.id, pid: orig.pid, filename: orig.filename }
         end
         out << json
      end
      return out
   end

   private
   def get_component_manifest(obj)
      out  = []
      obj.master_files.order(filename: :asc).each do |mf|
         tech_meta = mf.image_tech_meta
         if tech_meta.nil?
            unit_dir = mf.filename.split("_")[0]
            archive_file = File.join(ARCHIVE_DIR, unit_dir, mf.filename)
            begin
               logger.warn("MasterFile #{mf.filename} is missing image tech metadata. Creating from #{archive_file}")
               tech_meta = TechMetadata.create(mf, archive_file)
            rescue Exception => e
               logger.error("Unable to create tech metadata: #{e}. Skipping.")
               next
            end
         end
         json = { pid: mf.pid, filename: mf.filename, width: tech_meta.width, height: tech_meta.height }
         json[:title] = mf.title if !mf.title.nil?
         json[:description] = mf.description if !mf.description.nil?
         json[:exemplar] = mf.exemplar if mf.exemplar
         json[:text_source] = mf.text_source if !mf.text_source.nil?
         out << json
      end
      return out
   end

end
