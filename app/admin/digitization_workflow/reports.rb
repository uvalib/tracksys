ActiveAdmin.register_page "Reports" do
   menu :parent => "Digitization Workflow", if: proc{ current_user.admin? || current_user.supervisor? }

   content :title => 'Digitization Reports' do
      div :class => 'two-column' do
         panel "Average Page Completion Time", class:"tracksys-report" do
            div class: "report-filter" do
               d = Date.today.strftime("%F")
               s = '<label>Start Date:</label><input type="text" class="avg-time report-start query-datepicker">'
               e = "<label>End Date:</label><input type='text' class='avg-time report-end query-datepicker' value='#{d}'>"
               b = "<span id='avg-time' class='refresh-report mf-action-button'>Generate</span>"
               raw("#{s}#{e}#{b}")
            end

            div id: "project-time-generating", class: "generating" do
               div class: "wait" do "Please wait..." end
            end
            canvas id: "avg-times" do end
            div id: "avg-time-raw" do
               table do
                  tr do
                     th do "Category" end
                     th do "Workflow" end
                     th do "Units" end
                     th do "Total Mins" end
                     th do "Total Pages" end
                     th do "Avg. Mins" end
                  end
               end
            end
         end
      end
      div :class => 'two-column' do
         panel "Project Categories", class:"tracksys-report" do
            div id: "project-categories-generating", class: "generating" do
               div class: "wait" do "Please wait..." end
            end
            canvas id: "categories-chart" do end
               div id: "total-projects" do
               end
         end

         panel "Problem Statistics", class:"tracksys-report" do
            div class: "report-filter" do
               d = Date.today.strftime("%F")
               s = '<label>Start Date:</label><input type="text" class="problems report-start query-datepicker">'
               e = "<label>End Date:</label><input type='text' class='problems report-end query-datepicker' value='#{d}'>"
               b = "<span id='problems' class='refresh-report mf-action-button'>Generate</span>"
               raw("#{s}#{e}#{b}")
            end
            div id: "project-problems-generating", class: "generating" do
               div class: "wait" do "Please wait..." end
            end
            canvas id: "problems-chart" do end
         end
      end
   end
end
