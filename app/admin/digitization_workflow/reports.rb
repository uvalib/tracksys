ActiveAdmin.register_page "Reports" do
   menu :parent => "Digitization Workflow", if: proc{ current_user.admin? || current_user.supervisor? }

   content :title => 'Digitization Reports' do
      div :class => 'two-column' do
         panel "Average Page Completion Time", class:"tracksys-report" do
            render partial: 'report_filter', locals: { report: "avg-time" }

            div id: "project-time-generating", class: "generating" do
               div class: "wait" do "Please wait..." end
            end
            canvas id: "avg-times" do end
            div id: "avg-time-raw" do
               table do
                  tr do
                     th do "Category" end
                     th do "Units" end
                     th do "Total Mins" end
                     th do "Total Pages" end
                     th do "Avg. Mins" end
                  end
               end
            end
         end

         panel "Productivity", class:"tracksys-report" do
            render partial: 'report_filter', locals: { report: "productivity" }
            div id: "project-productivity-generating", class: "generating" do
               div class: "wait" do "Please wait..." end
            end
            canvas id: "productivity-chart" do end
            div id: "total-productivity-projects" do
            end
         end

         panel "Project Categories", class:"tracksys-report" do
            render partial: 'report_filter', locals: { report: "categories" }
            div id: "project-categories-generating", class: "generating" do
               div class: "wait" do "Please wait..." end
            end
            canvas id: "categories-chart" do end
            div id: "total-projects" do
            end
         end
      end

      div :class => 'two-column' do
         panel "Problem Statistics", class:"tracksys-report" do
            render partial: 'report_filter', locals: { report: "problems" }
            div id: "project-problems-generating", class: "generating" do
               div class: "wait" do "Please wait..." end
            end
            canvas id: "problems-chart" do end
         end

         panel "Rejection Statistics", class:"tracksys-report" do
            render partial: 'report_filter', locals: { report: "rejections" }
            div id: "project-rejections-generating", class: "generating" do
               div class: "wait" do "Please wait..." end
            end
            canvas id: "rejections-chart" do end
            div id: "total-assignments" do end
            div id: "rejections-raw" do
               table do
                  tr do
                     th do "Step Name" end
                     th do "Rejection Count" end
                     th do "Total Time" end
                     th do "Avg. Mins / Rejection" end
                  end
               end
            end
            div :class => 'two-column' do
               panel "Top Rejectors", id: "top-rejectors" do
               end
            end
            div :class => 'two-column' do
               panel "Most Rejected", id: "most-rejected" do
               end
            end
            div  style:"clear:both" do end
         end
      end
   end
end
