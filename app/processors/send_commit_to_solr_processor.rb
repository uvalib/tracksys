class SendCommitToSolrProcessor < ApplicationProcessor

  subscribes_to :send_commit_to_solr, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)  
    logger.debug "SendCommitToSolrProcessor received: " + message
    # TODO: Figure out what messagable class this processor will belong to
    # @messagable_id = 
    # @messagable_type =
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)
    
    solr = Solr::Connection.new("#{STAGING_SOLR_URL}", :autocommit => :on, :timeout => 3600000)
    solr.commit
    solr.optimize
    
    on_success "The commit signal has been sent to the Solr index at #{STAGING_SOLR_URL}."
  end
end
