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
      render partial: "modal"
   end

   page_action :assign, method: :post do
      ws = Workstation.find(params['workstation'])
      if ws.active_project_count == 0

         equipment = []
         scanner = false;
         body_cnt = lens_cnt = back_cnt = 0
         params['equipment'].each do |id|
            e = Equipment.find(id)
            scanner = true if e.type.downcase == "scanner"
            body_cnt += 1  if e.type.downcase == "camerabody"
            lens_cnt += 1 if e.type.downcase == "lens"
            back_cnt += 1 if e.type.downcase == "digitalback"
            equipment << e
         end
         if scanner
            if equipment.length > 1
               render plain: "A workstation can only have a camera assembly or a scanner, not both", status: :error and return
            end
         else
            if equipment.length < 3
               render plain: "Incomplete camera assembly", status: :error and return
            end
            if body_cnt != 1 || back_cnt != 1
               render plain: "Camera assembly must have 1 back and 1 body", status: :error and return
            end
            if lens_cnt > 2
               render plain: "A maximum of 2 lenses can be selected", status: :error and return
            end
         end
         ws.equipment.clear
         ws.equipment = equipment

         render json: ws.equipment.order(type: :asc).to_json(only: [:id, :name, :type, :serial_number])
      else
         render plain: "There are active projects assigned", status: :error
      end
   end

   controller do
       before_action :get_equipment
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
             render plain: e.errors.full_messages.to_sentence, status: :error
          end
       end

       def update
          e = Equipment.find(params[:id])
          if params[:active].blank?
             e.update(name: params[:name], serial_number: params[:serial])
          else
             if (params[:active] == "true")
                e.update(status: 0)
             else
                e.update(status: 1)
                ws = e.workstation
                if !ws.nil?
                   ws.update(status: 1)
                end
             end
          end
          render plain: "OK"
       end

       def destroy
          e = Equipment.find(params[:id])
          if e.workstation.nil?
             e.update(status: 2)
             render plain: "OK"
          else
             render plain: "#{e.name} is assigned to workstation #{e.workstation.name}", status: :error and return
          end
       end
    end
end
