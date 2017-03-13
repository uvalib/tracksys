ActiveAdmin.register_page "Equipment" do
   menu :parent => "Digitization Workflow", if: proc{ current_user.admin? || current_user.supervisor? }

   content do
      div :class => 'workstation-container' do
         div :class => 'block' do
            render partial: "workstation", locals: { workstations: workstations}
         end
      end

      div :class => 'columns-none' do
         div :class => 'two-column' do
            render partial: "equipment_list", locals: {title:"Camera Bodies", equipment: bodies, type: 'CameraBody'}
         end

         div :class => 'two-column' do
            render partial: "equipment_list", locals: {title:"Lenses", equipment: lenses, type: 'Lens'}
         end
      end

      div :class => 'columns-none' do
         div :class => 'two-column' do
            render partial: "equipment_list", locals: {title:"Digital Backs", equipment: backs, type: 'DigitalBack'}
         end

         div :class => 'two-column' do
            render partial: "equipment_list", locals: {title:"Scanners", equipment: scanners, type: 'Scanner'}
         end
      end
   end

   page_action :assign, method: :post do
      ws = Workstation.find(params['workstation'])
      if ws.active_project_count == 0
         ws.equipment.clear
         params['equipment'].each do |id|
            e = Equipment.find(id)
            ws.equipment << e
         end
         render json: ws.equipment.to_json(only: [:id, :name, :type, :serial_number])
      else
         render text: "There are active projects assigned", status: :error
      end
   end

   controller do
       before_filter :get_equipment
       def get_equipment
          @bodies = CameraBody.all.order(name: :asc)
          @backs = DigitalBack.all.order(name: :asc)
          @lenses = Lens.all.order(name: :asc)
          @scanners = Scanner.all.order(name: :asc)
          @workstations = Workstation.all.order(name: :asc)
       end

       def create
          e = Equipment.create(type: params[:type], name: params[:name], serial_number: params[:serial])
          if e.valid?
             html = render_to_string partial: "/admin/equipment/equipment_table", locals: {equipment: Equipment.where(type: params[:type])}
             render json: { html: html, id: e.id }
          else
             render text: e.errors.full_messages.to_sentence, status: :error
          end
       end

       def update
          e = Equipment.find(params[:id])
          if (params[:active] == "true")
             e.update(status: 0)
          else
             e.update(status: 1)
             ws = e.workstation
             if !ws.nil?
                ws.update(status: 1)
             end
          end
          render nothing: true
       end

       def destroy
          e = Equipment.find(params[:id])
          if e.workstation.nil?
             e.update(status: 2)
             render nothing: true
          else
             render text: "#{e.name} is assigned to workstation #{e.workstation.name}", status: :error and return
          end
       end
    end
end
