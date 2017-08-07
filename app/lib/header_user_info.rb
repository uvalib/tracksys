class HeaderUserInfo < ActiveAdmin::Component

  def build(index_classes, stuff)
     if acting_as_user?
        div id: "login-info", class: "acting-as" do
           div  do
             span :class=>"act_as" do
                "Acting as:"
             end
             span do
                link_to "#{current_user.full_name}", "/admin/staff_members/#{current_user.id}"
             end
           end
           div  do
             link_to "Exit", "/admin/staff_members/#{current_user.id}/exit", method: "POST"
           end
        end
     else
        div id: "login-info" do
           link_to "#{current_user.full_name}", "/admin/staff_members/#{current_user.id}"
        end
     end

  end
  def default_class_name
    "header-item tabs"
  end
end
