class Api::SolrController < ApplicationController

   # get a csv list of pids for all changed items
   # (metadata and master file) since the date specified in the params
   #
   def index
      ts = params[:timestamp]
      render :text=>"Timestamp is required", status: :bad_request and return if ts.blank?
      date_str=""
      begin
         dt = DateTime.strptime(ts.to_s,'%s')
         date_str = dt.strftime("%Y-%m-%d")
      rescue Exception=>e
         render :text=>"Invalid date", status: :bad_request and return
      end

      pids = []
      Rails.logger.info "Looking for DL updates since #{date_str}"
      Metadata.where("date_dl_ingest is not null and (date_dl_ingest >= ? or date_dl_update >= ?)", date_str,date_str).find_each do |o|
         pids << o.pid
      end

      # pids = []
      # Metadata.where("date_dl_ingest is not null and discoverability = 1").find_each do |o|
      #    pids << o.pid
      # end

      render :text=>pids.join(","), :status=>:ok
   end

   # Get the index record for the pid specified
   #
   def show
      render :text=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")

      #parse pid for item identity; format TS[B|M]:[id]
      pid_bits = params[:pid].split(":")
      id = pid_bits.last
      resource_type = pid_bits.first[2].upcase
      if resource_type == "B"
         object = Metadata.find(id)
      elsif resource_type == "M"
         object = MasterFile.find(id)
      else
         # see if it is an old-style PID
         object = Metadata.find_by(pid: params[:pid])
         if object.nil?
            object = MasterFile.find_by(pid: params[:pid])
         end
         render :text=>"PID is invalid", status: :bad_request and return if object.nil?
      end

      render :xml=> Hydra.solr(object)
   end
end
