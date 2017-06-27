class Api::FulltextController < ApplicationController
   def show
      types = ["transcription", "description", "title"]
      render :text=>"PID is required", status: :bad_request and return if params[:pid].nil?
      render :text=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")
      render :text=>"Type is required", status: :bad_request and return if params[:type].nil?
      render :text=>"Type is invalid", status: :bad_request and return if  !types.include? params[:type]

      # check each model that can have a PID to find a match. metadata takes precedence
      object = Metadata.find_by(pid: params[:pid])
      if object.nil?
         type = "master_file"
         object = MasterFile.find_by(pid: params[:pid])
      else
         type = object.type.underscore
      end

      render :text=>"Could not find PID", status: :not_found and return if object.nil?

      if type == "master_file"
         render plain: object.transcription_text.gsub(/\s+/, ' ').strip if params[:type] == "transcription" && !object.transcription_text.blank?
         render plain: object.description.gsub(/\s+/, ' ').strip if params[:type] == "description" && !object.description.blank?
         render plain: object.title.gsub(/\s+/, ' ').strip if params[:type] == "title" && !object.title.blank?
      else
         out = ""
         out << object.title if params[:type] == "title" && !object.title.blank?
         object.master_files.each do |mf|
            out << "\n" if out.length > 0
            out << mf.transcription_text if params[:type] == "transcription" && !mf.transcription_text.blank?
            out << mf.description if params[:type] == "description" && !mf.description.blank?
            out << mf.title if params[:type] == "title" && !mf.title.blank?
         end
         render plain: out.gsub(/\s+/, ' ').strip
      end
   end
end
