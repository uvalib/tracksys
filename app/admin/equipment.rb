ActiveAdmin.register_page "Equipment" do
   menu :parent => "Miscellaneous"

   content do
      div :class => 'workstation-container' do
         render partial: "workstation", locals: { workstations: workstations}
      end

      div :class => 'columns-none' do
         div :class => 'two-column' do
            render partial: "equipment_list", locals: {title:"Camera Bodies", equipment: bodies}
         end

         div :class => 'two-column' do
            render partial: "equipment_list", locals: {title:"Lenses", equipment: lenses}
         end
      end

      div :class => 'columns-none' do
         div :class => 'two-column' do
            render partial: "equipment_list", locals: {title:"Digital Backs", equipment: backs}
         end

         div :class => 'two-column' do
            render partial: "equipment_list", locals: {title:"Scanners", equipment: scanners}
         end
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
