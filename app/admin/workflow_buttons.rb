ActiveAdmin.register_page "WorkflowStart" do
  menu :label => 'Workflow Buttons', :parent => "Miscellaneous"

  content do
    panel "Buttons" do
      div :class => 'workflow_button' do button_to "Start Finalization on digiserv-production", admin_workflow_start_start_finalization_production_path, :user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s), :method => :get end
      div :class => 'workflow_button' do button_to "Start Finalization on digiserv-migration", admin_workflow_start_start_finalization_migration_path, :user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s), :method => :get end
      div :class => 'workflow_button' do button_to "Start Manual Stornext Upload on digiserv-prodution", admin_workflow_start_start_manual_upload_to_archive_production_path, :method => :get end
      div :class => 'workflow_button' do button_to "Start Manual Stornext Upload on digiserv-migration", admin_workflow_start_start_manual_upload_to_archive_migration_path, :user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s), :method => :get end
    end
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

  controller do 
    require 'activemessaging/processor'
    include ActiveMessaging::MessageSender

    publishes_to :start_manual_upload_to_archive_production
  end
end