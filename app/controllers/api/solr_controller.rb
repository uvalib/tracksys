class Api::SolrController < ApplicationController

   # get a list of all published catalog keys
   #
   def published
      file = Tempfile.new('published')
      first = true
      pid = !params[:pid].nil?
      SirsiMetadata.where("date_dl_ingest is not null").find_each do |m|
         file.write(",") if !first
         first = false
         if pid
            file.write(m.pid)
         else
            file.write(m.catalog_key)
         end
      end
      file.rewind
      file.close
      send_file(file.path, disposition: :inline)
   end

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
      Metadata.where("date_dl_ingest is not null and type<>? and (date_dl_ingest >= ? or date_dl_update >= ?)", "SirsiMetadata", date_str,date_str).find_each do |o|
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

      # From the above index method, the only thing that will be returned and used here are
      # METADATA records. No need to generically handle metadata, masterfile and component
      metadata = Metadata.find_by(pid: params[:pid])
      if metadata.nil?
         render :text=>"PID is invalid", status: :bad_request and return if metadata.nil?
      else
         render :xml=> Hydra.solr(metadata)
      end
   end
end
