class BaseJob
   # Execute the job asynchronously. Always the start of a workflow
   #
   def self.exec(message)
      job = self.new()
      job.init_status(message)
      job.delay.perform(message)
   end

   # Execute the job synchronously. If the job context is set, this is part of
   # a larger workflow.
   #
   def self.exec_now(message, workflow_context = nil)
      job = self.new()
      if workflow_context.nil?
         job.init_status(message)
      else
         # reuse status/logger from preceeding workflow
         job.chain_workflows(workflow_context)
      end

      job.perform(message)

      # nil context means this is the start point of a workflow
      # once we are out of the perform, the workflow is complete.
      # Update the status object
      if workflow_context.nil?
         job.complete()
      end
   end

   def chain_workflows(workflow_context)
      @logger = workflow_context.logger
      @status = workflow_context.status_object
   end

   # Init the job status record for this workflow
   #
   def init_status(message)
      @status = JobStatus.create()
      set_originator(message)
   end
   def set_originator(message)
      raise "Derived jobs must override set_originator!"
   end

   # Start logging and update status, then launch into workflow
   #
   def perform(message)
      job_log_dir = File.join(Rails.root,"log", "jobs")
      if !Dir.exists? job_log_dir
         FileUtils.mkdir_p job_log_dir
      end

      log_file_path = File.join(job_log_dir, "job_#{@status.id}.log")
      @logger = Logger.new(log_file_path)
      @logger.formatter = proc do |severity, datetime, progname, msg|
         "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} : #{severity} : #{msg}\n"
      end
      @logger.info "Starting #{self.class.name} with params: #{message.to_json}"

      # Flag job started running
      @status.update_attributes(:started_at => DateTime.now, :status=>"running")

      # all subclasses extend this method to define their job
      do_workflow(message)
   end

   # Extension point for all jobs derived from BaseJob
   #
   def do_workflow(message)
      raise "Derived jobs must override do_workflow!"
   end

   # Accessors for status and log. Used when jobs are chained together into workflows
   # to keep continuity of status / logging throughout
   def status_object
      @status
   end
   def logger
      @logger
   end

   # When jobs fail, remove them from the queue
   #
   def destroy_failed_jobs?
      return true
   end
   def max_attempts
      return 1
   end

   # Delayed job hook: Called when job has successfully completed
   #
   def success(job)
      complete()
   end

   # Delayed job error hook. Called when an exception is raised in a running job
   # Pass it along to the tracksys error handling
   #
   def error(job, exception)
      # if this error was raised by on_error to end processing, the
      # status will have been bumped to failure. If status is still running
      # this error is the result of some other exception. Log it and kill processing
      if @status.status == "running"
         @logger.fatal exception.message
         @logger.fatal exception.backtrace.join("\n")
         @status.update_attributes(:ended_at => DateTime.now, :status=>"failure", :error=>exception.message, :backtrace=>exception.backtrace.join("\n"))
      end
   end

   # Helper to make job names look like the original processor names
   #
   def set_workflow_type
     @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch("#{self.class.name.demodulize}Processor")
   end

   # Workflow is complete. Mark jobs status as done, update timestamps
   #
   def complete()
      @logger.info "Workflow #{self.class.name} has completed successfully"
      @status.update_attributes(:ended_at => DateTime.now, :status=>"success")
   end

   #
   # Job Logging Methods
   #
   def on_success(message)
      @logger.info message
   end

   # Sends a warning message, where "warning" is defined as a message that you
   # want to log without terminating processing. When you call this method like
   # so:
   #   on_warning "My message"
   # the message is logged, but then your code continues to run.
   #
   def on_failure(message)
      @status.update_attribute(:failures, (@status.failures+1) )
      @logger.error message
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
         @logger.error err.message
         @logger.error err.backtrace.join("\n")
         @status.update_attribute(:failures, (@status.failures+1) )
      else
         if err.is_a? Exception
            @logger.fatal err.message
            @logger.fatal err.backtrace.join("\n")
            @status.update_attributes(:ended_at => DateTime.now, :status=>"failure", :error=>err.message, :backtrace=>err.backtrace.join("\n"))
         else
            @logger.fatal err
            @status.update_attributes(:ended_at => DateTime.now, :status=>"failure", :error=>err, :backtrace=>caller.join("\n"))
         end

         # Stop processing
         raise err
      end
   end
end
