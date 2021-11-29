class Api::FinalizeController < ApplicationController
   # Start finializeation of a unit. Called from the DPG viewer
   #
   def finalize
      params.permit(:unit_id)
      unit_id = params[:unit_id]
      if unit_id.blank?
         render plain: "unit_id is required", status: :bad_request
         return
      end

      unit = Unit.find_by(id: unit_id)
      if unit.nil?
         render plain: "invalid unit id", status: :bad_request
         return
      end

      Rails.logger.info("Start finalization for unit [#{unit_id}]")
      FinalizeUnit.exec({unit_id: unit.id})
      render plain: "finalization started", status: :ok
   end
end