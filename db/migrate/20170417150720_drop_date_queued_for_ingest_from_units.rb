class DropDateQueuedForIngestFromUnits < ActiveRecord::Migration
  def change
     remove_column :units, :date_queued_for_ingest, :datetime
  end
end
