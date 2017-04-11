class Admin::WorkstationsController < ApplicationController
   def create
      ws = Workstation.create(name: params[:name])
      if ws.valid?
         html = render_to_string partial: "/admin/equipment/workstation_row", locals: {ws: ws}
         render json: { html: html, id: ws.id }
      else
         render text: ws.errors.full_messages.to_sentence, status: :error
      end
   end

   def clear_equipment
      ws = Workstation.find(params[:id])
      if ws.active_project_count == 0
         ws.equipment.clear
         render nothing: true
      else
         render text: "There are active projects assigned", status: :error
      end
   end

   def destroy
      ws = Workstation.find(params[:id])
      if ws.active_project_count == 0
         ws.update(status: 2)
         render nothing: true
      else
         render text: "There are active projects assigned", status: :error
      end
   end

   def update
      ws = Workstation.find(params[:id])
      if (params[:active] == "true")
         if ws.equipment_ready?
            ws.update(status: 0)
         else
            render text: "Equipment is not ready", status: :error and return
         end
      else
         ws.update(status: 1)
      end
      render nothing: true
   end
end