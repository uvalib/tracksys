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
        td do link_to "", "" end
      end
    end
    # div do
    #   link_to "Orders Ready for Delivery (#{Order.ready_for_delivery.count})", "admin/orders?scope=ready_for_delivery"
    # end
  end

  section "Recent DL Items (20)", :width => '33%', :priority => 4, :namespace => :admin, :toggle => 'hide' do
    table_for Bibl.in_digital_library.limit(20) do
      column :call_number
      column ("Title") {|bibl| truncate(bibl.title, :length => 80)}
      column ("Thumbnail") {|bibl| image_tag("http://fedoraproxy.lib.virginia.edu/fedora/get/#{MasterFile.find_by_filename(bibl.exemplar).pid}/djatoka:jp2SDef/getRegion?scale=125", :height => '100')}
      column("Links") do |mf|
        div do
          link_to "Details", admin_master_file_path(mf), :class => "member_link view_link"
        end
      end
      # column ("") do |bibl|
      #   div do
      #     tweet_button(:via => 'UVaDigServ', :url => "http://search.lib.virginia.edu/catalog/#{bibl.pid}", :text => truncate("#{bibl.title}", :length => 80), :count => 'horizontal')
      #   end
      #   div do
      #     link_to "Pin It", "http://pinterest.com/pin/create/button/?#{URI.encode_www_form("url" => "http://search.lib.virginia.edu/catalog/#{bibl.pid}/view", "media" => "http://fedoraproxy.lib.virginia.edu/fedora/get/#{MasterFile.find_by_filename(bibl.exemplar).pid}/djatoka:jp2SDef/getRegion?scale=800", "description" => "#{bibl.title} &#183; #{bibl.creator_name} &#183; #{bibl.year} &#183; Albert and Shirley Small Special Collections Library, University of Virginia.")}", :class => "pin-it-button"
      #   end
      # end
    end
  end

  section "Buttons" do
     div do button_to "Start Finalization on digiserv-production", admin_workflow_start_start_finalization_production_url end
    div do button_to "Start Finalization on digiserv-migration", admin_workflow_start_start_finalization_migration_url end
    div do button_to "Start Manual Stornext Upload on digiserv-prodution", admin_workflow_start_start_manual_upload_to_archive_production_url end
    div do button_to "Start Manual Stornext Upload on digiserv-migration", admin_workflow_start_start_manual_upload_to_archive_migration_url end
  end

  # section "Recently Ingested into DL" do
  #   table_for Unit.in_repo.limit(30) do
  #     column("Call Number") {|unit| unit.bibl_call_number}
  #     column("Title") {|unit| truncate(unit.bibl_title, :length => 80)}
  #     column ("Thumbnail") {|unit| image_tag("http://fedoraproxy.lib.virginia.edu/fedora/get/#{MasterFile.find_by_filename(unit.bibl_exemplar).pid}/djatoka:jp2SDef/getRegion?scale=125", :height => '100')}
  #     column ("") do |unit|
  #       div do
  #         tweet_button(:via => 'UVaDigServ', :url => "http://search.lib.virginia.edu/catalog/#{unit.bibl_pid}", :text => truncate("#{unit.bibl_title}", :length => 80), :count => 'horizontal')
  #       end
  #       div do
  #         link_to "Pin It", "http://pinterest.com/pin/create/button/?#{URI.encode_www_form("url" => "http://search.lib.virginia.edu/catalog/#{unit.bibl_pid}/view", "media" => "http://fedoraproxy.lib.virginia.edu/fedora/get/#{MasterFile.find_by_filename(unit.bibl_exemplar).pid}/djatoka:jp2SDef/getRegion?scale=800", "description" => "#{unit.bibl_title} \n\n Albert and Shirley Small Special Collections Library, University of Virginia.")}", :class => "pin-it-button"
  #       end
  #     end
  #   end
  # end
end