class SendCommitToSolrProcessor < ApplicationProcessor

  subscribes_to :send_commit_to_solr, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)  
    logger.debug "SendCommitToSolrProcessor received: " + message
    
    solr = Solr::Connection.new("#{SOLR_URL}", :autocommit => :on)
    solr.commit
    solr.optimize
    
    on_success "The commit signal has been sent to the Solr index at #{SOLR_URL}."
  end
end
