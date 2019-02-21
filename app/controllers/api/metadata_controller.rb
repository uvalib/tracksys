class Api::MetadataController < ApplicationController
   def show
      render :plain=>"type is required", status: :bad_request and return if params[:type].blank?
      type = params[:type].strip.downcase
      types = ["mods", "brief", "desc_metadata"]
      render :plain=>"#{type} is not supported", status: :bad_request and return if !types.include? type
      render :plain=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")

      if type == "mods"
         md = XmlMetadata.find_by(pid: params[:pid])
         render plain: "PID #{params[:pid]} not found", status: :not_found and return if md.nil?
         render xml: md.desc_metadata and return
      end

      md = Metadata.find_by(pid: params[:pid])
      if md.nil?
         mf = MasterFile.find_by(pid: params[:pid])
         md = mf.metadata if !mf.nil?
      end
      if md.nil? && type == "brief"
         c = Component.find_by(pid: params[:pid])
         out = {pid: params[:pid]}
         out[:title] = c.title
         out[:title] = c.content_desc if out[:title].blank?
         out[:title] = c.label if out[:title].blank?
         out[:title] = "Untitled" if out[:title].blank?
         if c.has_exemplar?
            out[:exemplar] = c.exemplar_info(:small)[:filename]
         end
         if !c.master_files.first.nil?
            md = c.master_files.first.metadata
            out[:rights] = md.use_right.uri
            out[:creator] = md.creator_name
            out[:catalogKey] = md.catalog_key if !md.catalog_key.blank?
            out[:callNumber] = md.call_number if !md.call_number.blank?
         end
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
         if md.has_exemplar?
            out[:exemplar] = md.exemplar_info(:small)[:filename]
         end
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
