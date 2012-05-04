ActiveAdmin.register_page "WorkflowStart" do
  menu :label => 'Workflow Buttons', :parent => "Dashboard"

  page_action :start_finalization_production do
    message = ActiveSupport::JSON.encode( {:message => 'go'})
    publish :start_finalization_production, message
    flash[:notice] = "Items in /digiserv-production/finalization/10_dropoff have begun finalization workflow."
    redirect_to :back
  end


  page_action :start_finalization_migration do
    message = ActiveSupport::JSON.encode( {:message => 'go'})
    publish :start_finalization_migration, message
    flash[:notice] = "Items in /digiserv-migration/finalization/10_dropoff have begun finalization workflow."
    redirect_to :back
  end

  page_action :start_manual_upload_to_archive_production do
    message = ActiveSupport::JSON.encode( {:message => 'go'})
    publish :start_manual_upload_to_archive_production, message
    flash[:notice] = "Items in /digiserv-production/stornext_dropoff/#{Time.now.strftime('%A')}."
    redirect_to :back
  end

  page_action :start_manual_upload_to_archive_migration do
    message = ActiveSupport::JSON.encode( {:message => 'go'})
    publish :start_manual_upload_to_archive_migration, message
    flash[:notice] = "Items in /digiserv-migration/stornext_dropoff/#{Time.now.strftime('%A')}."
    redirect_to :back
  end

  content do
    div do button_to "Start Finalization on digiserv-production", admin_workflow_start_start_finalization_production_url end
    div do button_to "Start Finalization on digiserv-migration", admin_workflow_start_start_finalization_migration_url end
    div do button_to "Start Manual Stornext Upload on digiserv-prodution", admin_workflow_start_start_manual_upload_to_archive_production_url end
    div do button_to "Start Manual Stornext Upload on digiserv-migration", admin_workflow_start_start_manual_upload_to_archive_migration_url end
  end

#   controller do
# def start_finalization_production
#     message = ActiveSupport::JSON.encode( {:message => 'go'})
#     publish :start_finalization_production, message
#     flash[:notice] = "Items in /digiserv-production/finalization/10_dropoff have begun finalization workflow."
#     redirect_to :back
#   end
#   end

end