class Api::ManifestController < ApplicationController
   # Get a JSON listing of all master files that belong to the specified
   # PID. The PID can be from a metadata record or component
   #
   def show
      render :plain=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")
      pid = params[:pid]

      # First, determine type - Metadata or Component
      component = false
      obj = Metadata.find_by(pid: pid)
      if obj.nil?
         obj = Component.find_by(pid: pid)
         component = true
      end
      if obj.nil?
         render plain: "PID #{pid} was not found", status: :not_found
         return
      end

      out = []
      if component
         out = get_component_manifest(obj)
      else
         out = get_metadata_manifest(obj, params[:unit])
      end
      render json: JSON.pretty_generate(out)
   end

   private
   def get_metadata_manifest(obj, unit_id)
      if !unit_id.nil?
   		logger.info("Only including masterfiles from unit #{unit_id}")
         files = obj.master_files.includes(:image_tech_meta).joins(:unit).where("units.id=?", unit_id).order(filename: :asc)
   	elsif obj.type == "ExternalMetadata"
   		logger.info("This is External metadata; including all master files")
         files = obj.master_files.includes(:image_tech_meta).all.order(filename: :asc)
   	else
   		logger.info("Only including masterfiles from units in the DL")
         files = obj.master_files.includes(:image_tech_meta).joins(:unit).where("units.include_in_dl=1").order(filename: :asc)
      end

      out  = []
      files.each do |mf|
         json = { pid: mf.pid, filename: mf.filename, width: mf.image_tech_meta.width, height: mf.image_tech_meta.height }
         json[:title] = mf.title if !mf.title.nil?
         json[:description] = mf.description if !mf.description.nil?
         out << json
      end
      return out
   end

   private
   def get_component_manifest(obj)
      out  = []
      obj.master_files.order(filename: :asc).each do |mf|
         json = { pid: mf.pid, filename: mf.filename, width: mf.image_tech_meta.width, height: mf.image_tech_meta.height }
         json[:title] = mf.title if !mf.title.nil?
         json[:description] = mf.description if !mf.description.nil?
         out << json
      end
      return out
   end

end
