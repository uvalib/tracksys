class Admin::ItemsController < ApplicationController
   def destroy
      OrderItem.find(params[:id]).destroy()
      render plain: "OK"
   end

   def convert
      if params[:metadata_type] == "sirsi"
         if params[:metadata_id].blank?
            render json: {success: false, message: "SirsiMetadata is required"}, status: :bad_request
            return
         end
      elsif params[:metadata_type] == "archivesspace"
         if params[:tgt_as_uri].blank?
            render json: {success: false, message: "ArchivesSpace metadata lookup is required"}, status: :bad_request
            return
         else
            # Create the external AS metadata record if necessary...
            as = ExternalSystem.find_by(name: "ArchivesSpace")
            uri = params[:tgt_as_uri]
            as_md = ExternalMetadata.where("external_system_id=? and external_uri=?", as.id, uri).first
            if as_md.nil?
               as_md = ExternalMetadata.create( external_system: as, external_uri: uri,
                  use_right_id: 1, title: params[:tgt_as_title] )
            end
            params[:metadata_id] = as_md.id
         end
      else
         render json: {success: false, message: "Unknown metadata type"}, status: :bad_request
         return
      end

      unit = Unit.create( unit_params )
      if !unit.valid?
         render json: {success: false, message: unit.errors.full_messages.to_sentence}, status: :bad_request
         return
      end
      unit.update(unit_status: "approved")

      # this method may be called to create a unit without a source item.
      # in this case, the item id will be blank, and there is nothing to do
      if !params[:source_item_id].blank?
         item = OrderItem.find(params[:source_item_id])
         item.update(converted: 1)
      end

      # once a unit has been created, the order can be approved.
      # Exception id for external customers - a fee is required.
      order = Order.find(params[:order_id])
      approve_enabled = true
      approve_enabled = false if order.customer.external? && !order.fee.nil? && order.fee > 0

      render json: {success: true, item_id: params[:source_item_id], approve_enabled: approve_enabled}
   end

   def create_metadata
      md = SirsiMetadata.create( metadata_params )
      if !md.valid?
         render plain: md.errors.full_messages.to_sentence, status: :bad_request
         return
      end
      md.update(is_approved: 1)

      render plain: md.id
   end

   def metadata_params
      params.permit(
         :title, :creator_name, :call_number,
         :catalog_key, :barcode, :use_right_id, :availability_policy_id,
         :resource_type_id, :genre_id, :discoverability, :is_personal_item,
         :is_manuscript
      )
   end

   def unit_params
      params.permit(
         :metadata_id, :intended_use_id, :patron_source_url, :special_instructions,
         :staff_notes, :complete_scan, :throw_away, :include_in_dl, :order_id, :converted
      )
   end
end
