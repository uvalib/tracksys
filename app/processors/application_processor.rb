class ApplicationProcessor < ActiveMessaging::Processor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  require 'logger'

  # This method is called whenever an exception is raised within on_message.
  # Handles StandardError exceptions and keeps processing. Other exceptions
  # are raised, terminating processing.
  #
  # Have on_error throw ActiveMessaging::AbortMessageException when you want a
  # message to be aborted/rolled back, meaning that it can and should be
  # retried (idempotency matters here). Retry logic varies by broker - see
  # individual adapter code and docs for how it will be treated
  def on_error(err)
    if err.is_a? StandardError
      # Send message to tracksys automation_message queue (for centralized error
      # handling for both deligen and tracksys)
      msg = ActiveSupport::JSON.encode({ :active_error => true, :messagable_id => @messagable_id, :messagable_type => @messagable_type, :pid => @pid, :message_type => 'error', :app => 'tracksys', :processor => self.class.name.demodulize, :workflow_type => @workflow_type, :message => err.message, :class_name => err.class.name, :backtrace => err.backtrace.join("\n")})
      publish :automation_message, msg
      on_log('error', err)
     else
      raise err
    end
  end

  # Sends a success message (to tracksys automation_message queue, which we're
  # actually using for error, failure and success messages, for centralized
  # message handling for both deligen and tracksys)
  def on_success(message)
    msg = ActiveSupport::JSON.encode({ :messagable_id => @messagable_id, :messagable_type => @messagable_type, :pid => @pid, :message_type => 'success', :app => 'tracksys', :processor => self.class.name.demodulize, :workflow_type => @workflow_type, :message => message})
    publish :automation_message, msg
    on_log('success', message)
  end

  # Sends a warning message, where "warning" is defined as a message that you
  # want to log without terminating processing. When you call this method like
  # so:
  #   on_warning "My message"
  # the message is published to the automation_message processor, but then your
  # code continues to run.
  def on_failure(message)
    msg = ActiveSupport::JSON.encode({ :messagable_id => @messagable_id, :messagable_type => @messagable_type, :pid => @pid, :message_type => 'failure', :app => 'tracksys', :processor => self.class.name.demodulize, :workflow_type => @workflow_type, :message => message})
    publish :automation_message, msg
    on_log('failure', message)
  end

  # This method is designed to channel different types of messages to appropriate logs.  It is incomplete and currently
  # only the 'info' conditional works.
  def on_log(status, message)
    log = Logger.new("#{RAILS_ROOT}/log/messaging_log.log")
    if status == 'success'
      log.info("Success #{Time.now} - #{message}")
    elsif status == 'failure'
      log.fatal("Failure #{Time.now} - #{message}")
    elsif status == 'error'
      log.error("Error #{Time.now} - #{message}")
    else
      raise "Message sent to messaging_log is of an unkown type."
    end
  end
end
