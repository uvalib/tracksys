ActiveAdmin.register JobStatus do
   menu :priority => 8, if: proc{ !current_user.viewer? }
   actions :all, :except => [:edit, :new]

   filter :name_starts_with, :label=>"Job Type"
   filter :originator_type, :as => :select, :collection => ['Metadata', 'MasterFile', 'Order', 'Unit'], :label => "Object"
   filter :originator_id, :as => :numeric, :label => "Object ID"
   filter :status, :as => :select, :collection => [ :pending, :running, :success, :failure ]
   filter :created_at, :label => "Submitted"
   filter :started_at, :label => "Started"
   filter :ended_at, :label => "Finished"

   # Job Status Index
   #
   index :title=>"Recent Job Statuses", :row_class => -> record { record.status_class } do
      selectable_column
      column ("Job ID"), sortable: :id do |job_status|
         job_status.id
      end
      column ("Job Type"), sortable: :name do |job_status|
         job_status.name
      end
      column ("Associated Object") do |job_status|
         if job_status.originator
            link_to "#{job_status.originator_type} #{job_status.originator_id}", polymorphic_path([:admin, job_status.originator])
         else
            "None"
         end
      end
      column ("Status") do |job_status|
         job_status.status.slice(0,1).capitalize + job_status.status.slice(1..-1)
      end
      column ("Warnings") do |job_status|
         job_status.failures
      end
      column ("Submitted"), sortable: :created_at do |job_status|
         format_datetime job_status.created_at
      end
      column ("Started"), sortable: :started_at do |job_status|
         format_datetime job_status.started_at
      end
      column ("Finshed"), sortable: :finished_at do |job_status|
         format_datetime job_status.ended_at
      end
      column("") do |job_status|
         div do
            link_to "Details", resource_path(job_status), :class => "member_link view_link"
         end
      end
   end

   # Workflow status Details
   #
   show :title => proc {|s| "Job #{s.id} Status "} do
      div :class => 'two-column' do
         panel "Summary" do
            attributes_table_for job_status do
               row ("Workflow") do |job_status|
                  job_status.name
               end
               row ("Status") do |job_status|
                  job_status.status.slice(0,1).capitalize + job_status.status.slice(1..-1)
               end
               row ("Warnings") do |job_status|
                  job_status.failures
               end
            end
         end
      end

      div :class => 'two-column' do
         panel "Technical Details" do
            attributes_table_for job_status do
               row ("Submitted") do |job_status|
                  format_datetime job_status.created_at
               end
               row ("Started") do |job_status|
                  format_datetime job_status.started_at
               end
               row ("Finshed") do |job_status|
                  format_datetime job_status.ended_at
               end
               row ("Associated Object") do |job_status|
                  if job_status.originator
                     link_to "#{job_status.originator_type} #{job_status.originator_id}", polymorphic_path([:admin, job_status.originator])
                  else
                     "None Available"
                  end
               end
            end
         end
      end


      div :class => 'columns-none' do
         panel "Workflow Log", :class=>"log-panel" do
            render 'job_log'
         end
      end

   end

   controller do
       def show
         @err_msg = JobStatus.find(params[:id]).error
         logpath = File.join(Rails.root,  "log", "jobs", "job_#{params[:id]}.log")
         f = File.open(logpath, "r")
         log = f.read
         f.close
         log.gsub! /,/, ", "
         @job_log = log.split("\n")
         show!
       end
   end

end
