class Admin::ItemsController < ApplicationController
   def destroy
      OrderItem.find(params[:id]).destroy()
      render plain: "OK"
   end

   def convert
      if params[:metadata_id].blank?
         render json: {success: false, message: "Metadata ID is required"}, status: :bad_request
         return
      end

      unit = Unit.create( unit_params )
      if !unit.valid?
         render json: {success: false, message: unit.errors.full_messages.to_sentence}, status: :bad_request
         return
      end
      unit.update(unit_status: "approved")

      item = OrderItem.find(params[:source_item_id])
      item.update(converted: 1)

      # once a unit has been created, the order can be approved.
      # Exception id for external customers - a fee is required.
      order = Order.find(params[:order_id])
      approve_enabled = true
      approve_enabled = false if order.customer.external? && (order.fee_estimated.nil? || order.fee_actual.nil?)

      render json: {success: true, item_id: item.id, approve_enabled: approve_enabled}
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
