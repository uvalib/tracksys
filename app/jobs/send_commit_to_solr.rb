class SendCommitToSolr < BaseJob

   def set_originator(message)
      # This has no messagable class / ID
   end

   def do_workflow(message)
    begin
       solr = Solr::Connection.new("#{STAGING_SOLR_URL}", :autocommit => :on, :timeout => 3600000)
       solr.commit
       on_success "The commit signal has been sent to the Solr index at #{STAGING_SOLR_URL}."
    rescue Errno::ECONNREFUSED
      on_failure("Connection to Solr #{STAGING_SOLR_URL} was refused")
    end
  end
end
