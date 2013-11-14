ActiveAdmin.register_page "Dashboard" do
  menu :priority => 1
  
  content do
    div :class => 'three-column' do 
      panel "Active Errors (#{AutomationMessage.has_active_error.count})", :namespace => :admin, :priority => 1, :toggle => 'show' do
        table do
          tr do
            td do "Archiving Workflow" end
            td do link_to "#{AutomationMessage.archive_workflow.has_active_error.count}", admin_automation_messages_path(:q => {:active_error_eq => true}, :scope => 'archive') end
          end
          tr do
            td do "QA Errors" end
            td do link_to "#{AutomationMessage.qa_workflow.has_active_error.count}", admin_automation_messages_path(:q => {:active_error_eq => true}, :scope => 'qa') end
          end
          tr do
            td do "Delivery Errors" end
            td do link_to "#{AutomationMessage.delivery_workflow.has_active_error.count}", admin_automation_messages_path(:q => {:active_error_eq => true}, :scope => 'delivery') end
          end
          tr do
            td do "Patron Approval Errors" end
            td do link_to "#{AutomationMessage.patron_workflow.has_active_error.count}", admin_automation_messages_path(:q => {:active_error_eq => true}, :scope => 'patron') end
          end
          tr do
            td do "Repository Wofkflow Errors" end
            td do link_to "#{AutomationMessage.repository_workflow.has_active_error.count}", admin_automation_messages_path(:q => {:active_error_eq => true}, :scope => 'repository') end
          end
        end
      end
    end

    div :class => 'three-column' do
      panel "Finalization", :width => '33%', :namespace => :admin, :priority => 2, :toggle => 'show' do
        table do
          tr do
            td do "Unfinished Units of Partially Finalized Orders" end
            td do link_to "#{Unit.uncompleted_units_of_partially_completed_orders.count}", admin_units_path( :order => 'id_desc', :page => '1', :scope => 'uncompleted_units_of_partially_completed_orders') end
          end
          tr do
            td do "Orders Ready for Delivery" end
            td do link_to "#{Order.ready_for_delivery.count}", admin_orders_path( :order => 'id_desc', :page => '1', :scope => 'ready_for_delivery') end
          end
          tr do
            td do "Burn Orders to DVD" end
            td do link_to "#{Order.ready_for_delivery.has_dvd_delivery.count}", admin_orders_path( :order => 'id_desc', :page => '1', :scope => 'ready_for_delivery', :q => { :dvd_delivery_location_id_is_null => 'true'}) end
          end 
        end
      end
    end

    div :class => 'three-column' do 
      panel "Finalization Workflow Buttons", :width => '33%', :priority => 3, :namespace => :admin, :toggle => 'show' do
        div :class => 'workflow_button' do button_to "Finalize digiserv-production", admin_dashboard_start_finalization_production_path, :user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s), :method => :get end
        div :class => 'workflow_button' do button_to "Finalize digiserv-migration", admin_dashboard_start_finalization_migration_path, :user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s), :method => :get end
        div :class => 'workflow_button' do button_to "Manual Upload digiserv-prodution", admin_dashboard_start_manual_upload_to_archive_production_path, :method => :get end
        div :class => 'workflow_button' do button_to "Manual Upload digiserv-migration", admin_dashboard_start_manual_upload_to_archive_migration_path, :user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s), :method => :get end
        div :class => 'workflow_button' do button_to "Manual Upload lib_content37", admin_dashboard_start_manual_upload_to_archive_batch_migration_path, :user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s), :method => :get end
      end
    end

    div :class => 'three-column' do
      panel "Recent DL Items (20)", :priority => 4, :toggle => 'show' do
        table_for Bibl.in_digital_library.limit(20) do
          column :call_number
          column ("Title") {|bibl| truncate(bibl.title, :length => 80)}
          column ("Thumbnail") do |bibl| 
            if bibl.exemplar?
              image_tag("http://fedoraproxy.lib.virginia.edu/fedora/objects/#{MasterFile.find_by_filename(bibl.exemplar).pid}/methods/djatoka:StaticSDef/getThumbnail?")
            else "no thumbnail"
            end
          end
          column("Links") do |bibl|
            div do
              link_to "Details", admin_bibl_path(bibl), :class => "member_link view_link"
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
        end
      end
    end

    div :class => 'three-column' do
      panel "Digital Library Buttons", :priority => 5, :toggle => 'show' do
        div :class => 'workflow_button' do button_to "Commit Records to Solr", admin_dashboard_update_all_solr_docs_path, :user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s), :method => :get end
      end
    end

    div :class => 'three-column' do
      panel "Statistics", :priority => 6, :toggle => 'show' do
        div :class => 'workflow_button' do
          render 'admin/stats_report'
        end
        div :class => 'workflow_button' do
          button_to "Generate DL Manifest", create_dl_manifest_admin_bibls_path, :method => :get
        end
        tr do
          td do
            "Total unpaid invoices:"
          end
          td do
            link_to "#{number_to_currency(Order.unpaid.sum(&:fee_actual), :precision => 0)}", admin_orders_path( :page => 1, :scope => 'unpaid', :order => 'fee_actual_desc'  )
          end        
        end
      end
    end
  end

  page_action :get_yearly_stats do 
    message = ActiveSupport::JSON.encode( {:year => params[:year]} )
    publish :create_stats_report, message
    flash[:notice] = "Stats Report Being Created.  Find at /digiserv-production/administrative/stats_reports/.  Give three minutes for production."
    redirect_to :back
  end

  page_action :push_staging_to_production do 
    begin
      FileUtils.touch '/lib_content27/tracksys_prod_solr/copy_to_production'
      flash[:notice] = "Records will be available through Virgo at 6am."
    rescue Errno::EACCES
      flash[:notice] = "Something went wrong, contact Administrator."
    end
    redirect_to :back
  end

  page_action :start_finalization_production do
    message = ActiveSupport::JSON.encode( {:user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s)} )
    publish :start_finalization_production, message
    flash[:notice] = "Items in /digiserv-production/finalization/10_dropoff have begun finalization workflow."
    redirect_to :back
  end

  page_action :start_finalization_migration do
    message = ActiveSupport::JSON.encode( {:user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s)} )
    publish :start_finalization_migration, message
    flash[:notice] = "Items in /digiserv-migration/finalization/10_dropoff have begun finalization workflow."
    redirect_to :back
  end

  page_action :start_manual_upload_to_archive_batch_migration do
    @user = StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s)
    message = ActiveSupport::JSON.encode( {:user_id => @user.id } )
    publish :start_manual_upload_to_archive_batch_migration, message
    flash[:notice] = "Items in /lib_content37/Rimage/stornext_dropoff/#{Time.now.strftime('%A')}."
    redirect_to :back
  end

  page_action :start_manual_upload_to_archive_production do
    @user = StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s)
    message = ActiveSupport::JSON.encode( {:user_id => @user.id } )
    publish :start_manual_upload_to_archive_production, message
    flash[:notice] = "Items in /digiserv-production/stornext_dropoff/#{Time.now.strftime('%A')}."
    redirect_to :back
  end

  page_action :start_manual_upload_to_archive_migration do
    message = ActiveSupport::JSON.encode( {:user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s)} )
    publish :start_manual_upload_to_archive_migration, message
    flash[:notice] = "Items in /digiserv-migration/stornext_dropoff/#{Time.now.strftime('%A')}."
    redirect_to :back
  end

  page_action :update_all_solr_docs do
    message = ActiveSupport::JSON.encode( {:message => 'go'})
    publish :send_commit_to_solr, message
    flash[:notice] = "All Solr records have been committed to #{STAGING_SOLR_URL}."
    redirect_to :back
  end
  
  controller do 
    require 'activemessaging/processor'
    include ActiveMessaging::MessageSender
  end

end
