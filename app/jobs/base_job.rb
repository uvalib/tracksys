class BaseJob

   # Execute the job asynchronously
   #
   def self.exec(message)
      job = self.new()
      job.delay.perform(message)
   end

   # Execute the job synchronously
   #
   def self.exec_now(message)
      job = self.new()
      begin
         job.perform(message)
      rescue Exception => e
         job.on_error(e)
      end
   end

   # Helper to make job names look like the original processor names
   #
   def set_workflow_type
     @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch("#{self.class.name.demodulize}Processor")
   end

   # Delayed job error hook. Called when an exception is raised in a running job
   # Pass it along to the tracksys error handling
   #
   def error(job, exception)
      on_error(exception)
   end

   def on_success(message)
      msg = {
         :messagable_id => @messagable_id, :messagable_type => @messagable_type,
         :pid => @pid, :message_type => 'success', :app => 'tracksys',
         :processor => self.class.name.demodulize, :workflow_type => @workflow_type, :message => message}
      BaseJob.write_automation_message(msg)
   end

   # Sends a warning message, where "warning" is defined as a message that you
   # want to log without terminating processing. When you call this method like
   # so:
   #   on_warning "My message"
   # the message is logged, but then your code continues to run.
   #
   def on_failure(message)
      msg = {
         :messagable_id => @messagable_id, :messagable_type => @messagable_type,
         :pid => @pid, :message_type => 'failure', :app => 'tracksys', :processor => self.class.name.demodulize,
         :workflow_type => @workflow_type, :message => message}
      Job_Log.error(message)
      BaseJob.write_automation_message(msg)
   end

   # This method is called whenever an exception is raised within on_message.
   # Handles StandardError exceptions and keeps processing. Other exceptions
   # are raised, terminating processing.
   #
   # Have on_error throw ActiveMessaging::AbortMessageException when you want a
   # message to be aborted/rolled back, meaning that it can and should be
   # retried (idempotency matters here). Retry logic varies by broker - see
   # individual adapter code and docs for how it will be treated
   #
   def on_error(err)
      if err.is_a? StandardError
         msg = {
            :active_error => true, :messagable_id => @messagable_id, :messagable_type => @messagable_type,
            :pid => @pid, :message_type => 'error', :app => 'tracksys', :processor => self.class.name.demodulize,
            :workflow_type => @workflow_type, :message => err.message, :class_name => err.class.name,
            :backtrace => err.backtrace.join("\n")}
         Job_Log.info("Writing automation message for error #{err.message}")
         BaseJob.write_automation_message(msg)
      else
         Job_Log.fatal("Caught fatal error #{err}")
         raise err
      end
   end

   def self.write_automation_message(message)
      # If a message makes it to AutomationMessageProcessor without a messagable object
      # (i.e. messagable_id is empty and/or messagable_type is empty) make the default
      # behavior to assign the message to aec6v's StaffMember object.
      if message[:messagable_id] == nil || message[:messagable_id] == 'null' || message[:messagable_type] == nil || message[:messagable_type] == 'null'
         message[:messagable_id] = 2
         message[:messagable_type] = "StaffMember"
      end

      # Save values to tracksys database for later review by staff
      am = AutomationMessage.new
      message.each do |key,value|
         am.send "#{key}=".to_sym, value
      end

      begin
         am.save!
      rescue Exception => err
         Job_Log.error "Can't save message to database: #{err.message}\nMessage was:\n#{message}"
      end
   end
end
