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
      render :plain=>"Timestamp is required", status: :bad_request and return if ts.blank?
      date_str=""
      begin
         dt = DateTime.strptime(ts.to_s,'%s')
         date_str = dt.strftime("%Y-%m-%d")
      rescue Exception=>e
         render :plain=>"Invalid date", status: :bad_request and return
      end

      pids = []
      Rails.logger.info "Looking for DL updates since #{date_str}"
      if !params[:sirsi].nil?
         Metadata.where("date_dl_ingest is not null and type=? and (date_dl_ingest >= ? or date_dl_update >= ?)", "SirsiMetadata", date_str,date_str).find_each do |o|
            pids << o.catalog_key
         end
      else
         Metadata.where("date_dl_ingest is not null and type=? and (date_dl_ingest >= ? or date_dl_update >= ?)", "XmlMetadata", date_str,date_str).find_each do |o|
            pids << o.pid
         end
      end

      render :plain=>pids.join(","), :status=>:ok
   end

   # Get the index record for the pid specified
   #
   def show
      render :plain=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")

      # From the above index method, the only thing that will be returned and used here are
      # METADATA records. No need to generically handle metadata, masterfile and component
      metadata = Metadata.find_by(pid: params[:pid])
      if metadata.nil?
         render :plain=>"PID is invalid", status: :bad_request and return if metadata.nil?
      else
         if metadata.type == "SirsiMetadata"
            Rails.logger.warn "Invalid request for solr index record for SirsiMetadata #{metadata.pid}"
            render plain: "Tracksys cannot generate Solr index records for SirsiMetadata", status: :error
         else
            render :xml=> Hydra.solr(metadata, params[:no_external])
         end
      end
   end
end
