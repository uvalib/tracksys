class AdminController < ApplicationController
  def start_finalization_production
    message = ActiveSupport::JSON.encode( {:message => 'go'})
    publish :start_finalization_production, message
    flash[:notice] = "Items in /digiserv-production/finalization/10_dropoff have begun finalization workflow."
    redirect_to :back
  end

  def start_finalization_migration
    message = ActiveSupport::JSON.encode( {:message => 'go'})
    publish :start_finalization_migration, message
    flash[:notice] = "Items in /digiserv-migration/finalization/10_dropoff have begun finalization workflow."
    redirect_to :back
  end

  def start_manual_upload_to_archive_production
    message = ActiveSupport::JSON.encode( {:message => 'go'})
    publish :start_manual_upload_to_archive_production, message
    flash[:notice] = "Items in /digiserv-production/stornext_dropoff/#{Time.now.strftime('%A')}."
    redirect_to :back
  end

  def start_manual_upload_to_archive_migration
    message = ActiveSupport::JSON.encode( {:message => 'go'})
    publish :start_manual_upload_to_archive_migration, message
    flash[:notice] = "Items in /digiserv-migration/stornext_dropoff/#{Time.now.strftime('%A')}."
    redirect_to :back
  end
end