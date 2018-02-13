ActiveAdmin.register_page "Subreports" do
   menu false

   content :only=>:index, :title => 'Staff Projects' do
      staff = StaffMember.find(params[:user])
      if params[:type].include? "_reject"
         header = "QA project(s) with rejections"
         header = "Scannng project(s) with rejections" if  params[:type] == "scan_reject"
         type  = params[:type] .split("_")[0]
         rejections = true
      else
         header = "QA project(s)"
         header = "Scannng project(s)" if  params[:type] == "scan"
         type = params[:type]
         rejections = false
      end

      projects = Project.filter(type, staff.id, params[:workflow], params[:d0], params[:d1], rejections)
      h4 class:"rejection-header" do
         "#{projects.count} #{header} for #{staff.full_name}"
      end

      cnt = 0
      div class: "rejects-list" do
         projects.each do |project|
            render partial: "/admin/digitization_workflow/projects/card", locals: {project: project, footer: false, first: false}
            cnt +=1
            if cnt == 2
               cnt = 0
               div style: "clear:both;" do  end
            end
         end
      end
   end
end
