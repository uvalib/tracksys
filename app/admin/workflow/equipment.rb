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
            render partial: "equipment_list", locals: {title:"Camera Bodies", equipment: bodies, clazz: 'bodies'}
         end

         div :class => 'two-column' do
            render partial: "equipment_list", locals: {title:"Lenses", equipment: lenses, clazz: 'lenses'}
         end
      end

      div :class => 'columns-none' do
         div :class => 'two-column' do
            render partial: "equipment_list", locals: {title:"Digital Backs", equipment: backs, clazz: 'backs'}
         end

         div :class => 'two-column' do
            render partial: "equipment_list", locals: {title:"Scanners", equipment: scanners, clazz: 'scanners'}
         end
      end
   end

   page_action :assign, method: :post do
      ws = Workstation.find(params['workstation'])
      ws.equipment.clear
      params['equipment'].each do |id|
         e = Equipment.find(id)
         ws.equipment << e
      end
      render json: ws.equipment.to_json(only: [:id, :name, :type, :serial_number])
   end

   page_action :workstation, method: :post do
      if ( params[:act] == "create")
         ws = Workstation.create(name: params[:name])
         html = render_to_string partial: "workstation_row", locals: {ws: ws}
         render json: { html: html, id: ws.id }
      elsif params[:act] == "retire"
         ws = Workstation.find(params[:id])
         ws.update(status: 2)
         render nothing: true
      else
         render text: "Unsupported action", status: :bad_request
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
    end
end
