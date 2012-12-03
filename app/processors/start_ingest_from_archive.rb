class StartIngestFromArchiveProcessor < ApplicationProcessor

# start_ingest_from_archive - This script is to be triggered by a rake task begun by cron.

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :start_ingest_from_archive, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :update_unit_date_queued_for_ingest
   
  def on_message(message)
    hash = ActiveSupport::JSON.decode(message).symbolize_keys
    if hash[:unit_id]
      @unit_id = hash[:unit_id]
      @unit_dir = "%09d" % @unit_id
      @working_unit = Unit.find(@unit_id)
      @messagable_id = @unit_id
      @messagable_type = "Unit"
      @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)

      # Check to make sure that the Unit has been archived to a mounted Archive
      if @working_unit.archive.directory?
        @source = File.join(@working_unit.archive.directory, @unit_dir)
        message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :source => @source})
        publish :update_unit_date_queued_for_ingest, message
        on_success "The DL ingestion workflow for Unit #{@unit_id} has begun."
      else
        on_error "Unit #{@unit_id} has no directory from which to fetch material.  Check archival storage."
      end
    else
      ingestable_units = Unit.find(:all, :conditions => "include_in_dl = '1' AND date_queued_for_ingest IS NULL AND availability IS NOT NULL and date_archived IS NOT NULL")

      ingestable_units.each {|ingestable_unit|
        @unit_id = ingestable_unit.id
        @unit_dir = "%09d" % @unit_id
        @working_unit = Unit.find(@unit_id)
        @messagable_id = @unit_id
        @messagable_type = "Unit"
        @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)      

        # Check to make sure that the Unit has been archived to a mounted Archive
        if @working_unit.archive.directory?
          @source = File.join(@working_unit.archive.directory, @unit_dir)
          message = ActiveSupport::JSON.encode({ :unit_id => @unit_id, :source => @source})
          publish :update_unit_date_queued_for_ingest, message
          on_success "The DL ingestion workflow for Unit #{@unit_id} has begun."
        else
          on_error "Unit #{@unit_id} has no directory from which to fetch material.  Check archival storage."
        end
      }
    end
  end
end
