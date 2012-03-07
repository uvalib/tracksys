class UpdateRelsExtWithIndexerContentModelProcessor < ApplicationProcessor

  require 'fedora'

  subscribes_to :update_rels_ext_with_indexer_content_model, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)  
    logger.debug "QueueObjectsForFedoraProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Validate incoming message
    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?

    @unit_id = hash[:unit_id]
    @working_unit = Unit.find(@unit_id)
    @predicate = "info:fedora/fedora-system:def/model%23hasModel"
    @object = "info:fedora/uva-lib:indexableCModel"
    @contentType = "text/xml"

    # Will put all objects to be ingested into repo into an array called things
    things = Array.new

    @working_unit.bibls.each {|bibl| things << bibl }
    @working_unit.master_files.each {|mf| things << mf }
    @working_unit.components.each {|component| things << component }

    # For each ingestable thing related to a unit, update the RELS-EXT to include the indexer content model.
    # Then read the RELS-EXT from the repo and replace thing.rels_ext
    things.each {|thing|
      @pid = thing.pid
      subject = "info:fedora/#{thing.pid}"
      Fedora.add_relationship(thing.pid, subject, @predicate, @object, @contentType)
      thing.rels_ext = '<?xml version="1.0" encoding="UTF-8"?>' + "\n"
      thing.rels_ext += Fedora.get_datastream(thing.pid, 'RELS-EXT', 'xml')
      thing.save!
    }
  end
end
