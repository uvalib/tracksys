class Api::FulltextController < ApplicationController
   def show
      types = ["transcription", "description", "title"]
      render :plain=>"PID is required", status: :bad_request and return if params[:pid].nil?
      render :plain=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")
      render :plain=>"Type is required", status: :bad_request and return if params[:type].nil?
      render :plain=>"Type is invalid", status: :bad_request and return if  !types.include? params[:type]
      page_breaks = !params[:breaks].nil?

      # check each model that can have a PID to find a match. metadata takes precedence
      object = Metadata.find_by(pid: params[:pid])
      if object.nil?
         type = "master_file"
         object = MasterFile.find_by(pid: params[:pid])
      else
         type = object.type.underscore
      end

      render :plain=>"Could not find PID", status: :not_found and return if object.nil?

      if type == "master_file"
         render plain: object.transcription_text.gsub(/\s+/, ' ').strip if params[:type] == "transcription" && !object.transcription_text.blank?
         render plain: object.description.gsub(/\s+/, ' ').strip if params[:type] == "description" && !object.description.blank?
         render plain: object.title.gsub(/\s+/, ' ').strip if params[:type] == "title" && !object.title.blank?
      else
         uid = params[:unit]
         render :plain=>"Unit is required", status: :bad_request and return if  uid.nil?

         out = ""
         # Show some metadata about the object at the top of output if breaks are requeted 
         if page_breaks 
            if object.type == "SirsiMetadata"
               out << "[[ #{object.title} - #{object.call_number} ]]\n"
            else
               out << "[[ #{object.title} ]]\n"
            end
         end
         out << object.title if params[:type] == "title" && !object.title.blank?
         object.master_files.where(unit_id: uid).each do |mf|
            if page_breaks
               out << "[PAGE #{mf.filename.split("_").last.split(".").first}]\n" 
            else
               out << "\n" if out.length > 0
            end
            out << mf.transcription_text if params[:type] == "transcription" && !mf.transcription_text.blank?
            out << mf.description if params[:type] == "description" && !mf.description.blank?
            out << mf.title if params[:type] == "title" && !mf.title.blank?
         end
         render plain: out.gsub(/\ +/, ' ').strip
      end
   end

   def post_ocr #tsm:1686734
      render :plain=>"PID is required", status: :bad_request and return if params[:pid].nil?
      render :plain=>"Text is required", status: :bad_request and return if params[:text].nil?
      mf = MasterFile.find_by(pid: params[:pid])
      render plain: "PID not found", status: :not_found and return if mf.nil?
      if mf.text_source.blank? || mf.text_source == "ocr"
         # only update text if there is none or it is OCR
         mf.update(text_source: "ocr", transcription_text: params[:text])
         render plain: "Master File OCR text added", status: :ok
         return
      end

      render plain: "Master File already has Corrected OCR or Transcription text", status: :conflict
   end
end
