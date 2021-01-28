class Api::MetadataController < ApplicationController
   def show
      render :plain=>"type is required", status: :bad_request and return if params[:type].blank?
      type = params[:type].strip.downcase
      types = ["mods", "brief", "desc_metadata", "marc"]
      render :plain=>"#{type} is not supported", status: :bad_request and return if !types.include? type
      render :plain=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")

      # get the metadata record associated with the PID
      pid = params[:pid]
      md = Metadata.find_by(pid: pid)
      if md.nil?
         mf = MasterFile.find_by(pid: params[:pid])
         md = mf.metadata if !mf.nil?
      end
      if md.nil?
         render plain: "PID #{params[:pid]} not found", status: :not_found and return if md.nil?
      end

      if type == "marc"
         xml_string = Virgo.get_marc(md.catalog_key)
         render xml: xml_string
         return
      end

      if type == "mods"
         render :xml=> Hydra.desc(md) and return
      end

      if type == "desc_metadata"
         render :xml=> Hydra.desc(md) and return
      end
   end

   include ActionView::Helpers::TextHelper
   def search
      q = params[:q]
      out = []
      Metadata.where("title like ? or barcode like ? or pid like ? or call_number like ?",
         "%#{q}%", "#{q}%", "#{q}%", "%#{q}%").each do |h|
         bc = h.barcode
         bc = "N/A" if bc.nil?
         cn = h.call_number
         cn = "N/A" if cn.nil?
         out << {id: h.id, pid: h.pid, title: truncate(h.title, length: 50, separator: ' '),
            barcode: bc, call_number: cn, full: h.title}
      end
      render json: out
   end
end
