ActiveAdmin.register_page "Dashboard" do
   menu :priority => 1

   content do
      div :class => 'three-column' do
         panel "Recent DL Items (20)", :priority => 4, :toggle => 'show' do
            table_for Metadata.in_digital_library.limit(20) do
               column ("Title") {|metadata| truncate(metadata.title, :length => 80)}
               column ("Thumbnail") do |metadata|
                  if metadata.exemplar?
                     mf = MasterFile.find_by( filename: metadata.exemplar)
                     if mf.nil?
                        "missing thumbnail"
                     else
                        image_tag("#{Settings.iiif_url}/#{mf.pid}/full/!125,125/0/default.jpg")
                     end
                  else
                     "no thumbnail"
                  end
               end
               column("Links") do |metadata|
                  div do
                     if metadata.type == "XmlMetadata"
                        link_to "Details", "/admin/xml_metadata/#{metadata.id}", :class => "member_link view_link"
                     else
                        link_to "Details", "/admin/sirsi_metadata/#{metadata.id}", :class => "member_link view_link"
                     end
                  end
               end
            end
         end
      end

      div :class => 'three-column' do
         panel "Outstanding Orders", :priority => 5, :toggle => 'show' do
            table do
               tr do
                  td do "Orders Due Today" end
                  td do link_to "#{Order.due_today.count}", admin_orders_path(:order => 'date_due_desc', :page => '1', :scope => 'due_today') end
               end
               tr do
                  td do "Orders Due In A Week" end
                  td do link_to "#{Order.due_in_a_week.count}", admin_orders_path(:order => 'date_due_desc', :page => '1', :scope => 'due_in_a_week') end
               end
               tr do
                  td do "Orders Overdue (< 1 yr)" end
                  td do link_to "#{Order.overdue.count}", admin_orders_path(:order => 'date_due_desc', :page => '1', :scope => 'overdue') end
               end
               tr do
                  td do "Invoices Overdue (30 days or more)" end
                  td do link_to "#{Invoice.past_due.count}", admin_invoices_path(:order => 'date_invoice_desc', :page => '1', :scope => 'past_due') end
               end
               tr do
                  td do "Invoices Overdue (2nd notice)" end
                  td do link_to "#{Invoice.notified_past_due.count}", admin_invoices_path(:order => 'date_invoice_desc', :page => '1', :scope => 'notified_past_due') end
               end
               tr do
                  td do "Customers with unpaid orders" end
                  td do link_to "#{Customer.has_unpaid_invoices.count}", admin_customers_path(:customer => 'id_desc', :page => '1', :scope => 'has_unpaid_invoices')  end
               end
            end
         end

         panel "Recent Job Status Summary", :namespace => :admin, :priority => 1, :toggle => 'show' do
            table do
               tr do
                  td do "Pending Jobs" end
                  td do link_to "#{JobStatus.jobs_count('pending')}", admin_job_statuses_path(:q => {:status => 'pending'} ) end
               end
               tr do
                  td do "Running Jobs" end
                  td do link_to "#{JobStatus.jobs_count('running')}", admin_job_statuses_path(:q => {:status_eq => 'running'} ) end
               end
               tr do
                  td do "Successful Jobs" end
                  td do link_to "#{JobStatus.jobs_count('success')}", admin_job_statuses_path(:q => {:status_eq => 'success'} ) end
               end
               tr do
                  td do "Failed Jobs" end
                  td do link_to "#{JobStatus.jobs_count("failure")}", admin_job_statuses_path(:q => {:status_eq => 'failure'} ) end
               end
            end
         end

         panel "Finalization", :width => '33%', :namespace => :admin, :priority => 2, :toggle => 'show' do
            table do
               tr do
                  td do "Unfinished Units of Partially Finalized Orders" end
                  td do
                     link_to "#{Unit.uncompleted_units_of_partially_completed_orders.count}",
                     admin_units_path( :order => 'id_desc', :page => '1', :scope => 'uncompleted_units_of_partially_completed_orders')
                  end
               end
               tr do
                  td do "Orders Ready for Delivery" end
                  td do link_to "#{Order.ready_for_delivery.count}", admin_orders_path( :order => 'id_desc', :page => '1', :scope => 'ready_for_delivery') end
               end
            end
         end
      end

      if !current_user.viewer? && !current_user.student?
         div :class => 'three-column' do
            panel "Statistics", :priority => 6, :toggle => 'show' do
               div :class => 'workflow_button border-bottom' do
                  render 'admin/stats_report'
               end
               div :class => 'workflow_button border-bottom' do
                  button_to "Generate DL Manifest", "/admin/dashboard/create_dl_manifest", :method => :get
               end
               table :style=>"margin-bottom: 0" do
                  tr do
                     td do "Total unpaid invoices:" end
                     td do
                        link_to "#{number_to_currency(Order.unpaid.to_a.sum(&:fee_actual), :precision => 0)}",
                           admin_orders_path( :page => 1, :scope => 'unpaid', :order => 'fee_actual_desc'  )
                     end
                  end
               end
            end

            panel "PID Finder" do
               render 'admin/pid_finder'
            end
         end
      end
   end

   page_action :create_dl_manifest do
      CreateDlManifest.exec( {:staff_member => current_user } )
      redirect_to "/admin/dashboard", :notice => "Digital library manifest creation started.  Check your email in a few minutes."
   end

   page_action :get_yearly_stats do
      CreateStatsReport.exec( {:user_id=>current_user.id, :year => params[:year]} )
      flash[:notice] = "Stats Report Being Created. You will receive an email when report is ready."
      redirect_to "/admin/dashboard"
   end

   page_action :pid_lookup do
      object = Metadata.find_by(pid: params[:pid])
      if !object.nil?
         redirect_to "/admin/#{object.type.underscore}/#{object.id}" and return
      end

      object = MasterFile.find_by(pid: params[:pid])
      if !object.nil?
         redirect_to "/admin/master_files/#{object.id}" and return
      end
      object = Component.find_by(pid: params[:pid])
      if !object.nil?
         redirect_to "/admin/components/#{object.id}" and return
      end

      flash[:notice] = "Could not find PID #{params[:pid]}"
      redirect_to "/admin/dashboard"
   end
end
