class SendCommitToSolr < BaseJob

   def set_originator(message)
      # This has no messagable class / ID
   end

   def do_workflow(message)
    # TODO: Figure out what messagable class this processor will belong to
    # @messagable_id =
    # @messagable_type =

    solr = Solr::Connection.new("#{STAGING_SOLR_URL}", :autocommit => :on, :timeout => 3600000)
    solr.commit

    on_success "The commit signal has been sent to the Solr index at #{STAGING_SOLR_URL}."
  end
end
