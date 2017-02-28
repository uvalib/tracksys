ActiveAdmin.register_page "Staff Skills" do
   menu :parent => "Digitization Workflow", :priority => 3

   content do
      render partial: 'skills_matrix'
   end

   page_action :staff, :method => :get do
      skill_id = params[:skill]
      out = []
      StaffMember.joins(:skills).where("staff_skills.category_id=?", skill_id).each do |s|
         out << {id: s.id, name: s.full_name }
      end
      render json: out
   end
end
