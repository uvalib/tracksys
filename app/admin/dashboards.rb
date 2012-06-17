ActiveAdmin::Dashboards.build do
  
  section "Active Errors (#{AutomationMessage.has_active_error.count})", :width => '33%', :namespace => :admin, :priority => 1, :toggle => 'show' do
    table do
      tr do
        td do "Archiving Workflow" end
        td do link_to "#{AutomationMessage.archive_workflow.has_active_error.count}", admin_automation_messages_path(:q => {:active_error_eq => true}, :scope => 'archive_workflow') end
      end
      tr do
        td do "QA Errors" end
        td do link_to "#{AutomationMessage.qa_workflow.has_active_error.count}", "admin/automation_messages?scope=qa_workflow&q%5Bactive_error_eq%5D=true" end
      end
      tr do
        td do "Delivery Errors" end
        td do end
      end
    end
  end

  section "Finalization", :width => '33%', :namespace => :admin, :priority => 2, :toggle => 'show' do
    table do
      tr do
        td do "Orders Ready for Delivery" end
        td do link_to "#{Order.ready_for_delivery.count}", "admin/orders?scope=ready_for_delivery" end
      end
      tr do
        td do "Burn Orders to DVD" end
        td do link_to "#{Order.ready_for_delivery.has_dvd_delivery.count}", "admin/orders?scope=ready_for_dvd_burning" end
      end
      tr do
        td do "Unfinished Units of Partially Finalized Orders" end
        td do link_to "#{Unit.uncompleted_units_of_partially_completed_orders.count}", "admin/units?scope=uncompleted_units_of_partially_completed_orders" end
      end
    end
  end

  section "Buttons", :width => '33%', :priority => 3, :namespace => :admin, :toggle => 'show' do
    div :class => 'workflow_button' do button_to "Finalize digiserv-production", admin_workflow_start_start_finalization_production_path, :user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s), :method => :get end
    div :class => 'workflow_button' do button_to "Finalize digiserv-migration", admin_workflow_start_start_finalization_migration_path, :user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s), :method => :get end
    div :class => 'workflow_button' do button_to "Manual Upload digiserv-prodution", admin_workflow_start_start_manual_upload_to_archive_production_path, :method => :get end
    div :class => 'workflow_button' do button_to "Manual Upload digiserv-migration", admin_workflow_start_start_manual_upload_to_archive_migration_path, :user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s), :method => :get end
  end

  section "Recent DL Items (20)", :priority => 4, :toggle => 'show' do
    table_for Bibl.in_digital_library.limit(20) do
      column :call_number
      column ("Title") {|bibl| truncate(bibl.title, :length => 80)}
      column ("Thumbnail") {|bibl| image_tag("http://fedoraproxy.lib.virginia.edu/fedora/get/#{MasterFile.find_by_filename(bibl.exemplar).pid}/djatoka:jp2SDef/getRegion?scale=125", :height => '100')}
      column("Links") do |mf|
        div do
          link_to "Details", admin_bibl_path(mf), :class => "member_link view_link"
        end
      end
    end
  end


end