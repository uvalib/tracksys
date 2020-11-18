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
         md = XmlMetadata.find_by(pid: params[:pid])
         if !md.nil?
            # XML metadata is already in mods, just return it
            render xml: md.desc_metadata and return
         end
         md = SirsiMetadata.find_by(pid: params[:pid])
         if !md.nil?
            # Sirsi metadata needs to be transformed into mods
            render :xml=> Hydra.desc(md) and return
         end
         render plain: "PID #{params[:pid]} not found", status: :not_found and return if md.nil?
      end

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
