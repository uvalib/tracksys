class Api::MetadataController < ApplicationController
   def show
      render :plain=>"type is required", status: :bad_request and return if params[:type].blank?
      type = params[:type].strip.downcase
      render :plain=>"#{type} is not supported", status: :bad_request and return if type != "desc_metadata" && type != "brief"
      render :plain=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")

      md = Metadata.find_by(pid: params[:pid])
      if md.nil?
         md = MasterFile.find_by(pid: params[:pid])
      end
      if md.nil? && type == "brief"
         c = Component.find_by(pid: params[:pid])
         out = {pid: params[:pid], title: c.title}
         out[:exemplar] = c.exemplar if !c.exemplar.blank?
         md = c.master_files.first.metadata
         out[:rights] = md.use_right.uri
         out[:creator] = md.creator_name
         out[:catalogKey] = md.catalog_key if !md.catalog_key.blank?
         out[:callNumber] = md.call_number if !md.call_number.blank?
         render json: out and return
      end
      render :plain=>"PID is invalid", status: :bad_request and return if md.nil?

      if type == "desc_metadata"
         render :xml=> Hydra.desc(md) and return
      end

      if type == "brief"
         out = {pid: params[:pid], title: md.title, creator: md.creator_name, rights: md.use_right.uri }
         out[:catalogKey] = md.catalog_key if !md.catalog_key.blank?
         out[:callNumber] = md.call_number if !md.call_number.blank?
         out[:exemplar] = md.exemplar if !md.exemplar.blank?
         render json: out
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
