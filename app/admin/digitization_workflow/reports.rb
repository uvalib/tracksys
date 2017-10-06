# ActiveAdmin.register_page "Reports" do
#    menu :parent => "Digitization Workflow", if: proc{ current_user.admin? || current_user.supervisor? }
#
#    content :title => 'Digitization Reports' do
#       div :class => 'two-column' do
#          panel "Average Time to Complete", class:"tracksys-report" do
#             canvas id: "time-to-complete" do end
#          end
#       end
#       div :class => 'two-column' do
#          panel "Project Types", class:"tracksys-report" do
#             div id: "project-types-generating", class: "generating" do
#                div class: "wait" do "Please wait..." end
#             end
#             canvas id: "project-types" do end
#          end
#       end
#    end
# end
