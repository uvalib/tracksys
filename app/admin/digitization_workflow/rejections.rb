ActiveAdmin.register_page "Rejections" do
   menu false

   content :only=>:index do
      staff = StaffMember.find(params[:user])
      type = "QA"
      type = "Scannng" if  params[:type] == "scan"
      projects = Project.rejections(params[:type], staff.id, params[:d0], params[:d1])
      h4 class:"rejection-header" do
         "#{type} Rejections for #{staff.full_name}"
      end
      cnt = 0
      div class: "rejects-list" do
         projects.each do |project|
            render partial: "/admin/projects/card", locals: {project: project, no_footer: "true", first: false}
            cnt +=1
            if cnt == 2
               cnt = 0
               div style: "clear:both;" do  end
            end
         end
      end
   end
end
