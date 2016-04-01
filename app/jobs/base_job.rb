class BaseJob
   # Execute the job asynchronously. Always the start of a workflow.
   # The ID of the delayed job is returned so status can be polled
   #
   def self.exec(message)
      job = self.new()
      job_id = job.init_status(message)
      job.delay.perform(message)
      return job_id
   end

   # Execute the job synchronously. If the job context is set, this is part of
   # a larger workflow.
   #
   def self.exec_now(message, workflow_context = nil)
      job = self.new()

      # Is this being called from another job?
      if workflow_context.nil?
         # No: start a new workflow and create a new status object
         job.init_status(message)
      else
         # Called from anoter job; reuse status/logger from preceeding step in workflow
         job.reuse_context(workflow_context)
      end

      job.perform(message)

      # nil context means this is the start point of a workflow
      # once we are out of the perform, the workflow is complete.
      # Update the status object
      if workflow_context.nil?
         job.complete()
      end
   end

   # Init the job status record for this workflow
   #
   def init_status(message)
      @status = JobStatus.create(name: self.class.name)
      set_originator(message)
      originator = @status.originator
      if !originator.nil?
         originator.update_attribute(:job_statuses_count, originator.job_statuses_count+1)
      end
      return @status.id
   end
   def set_originator(message)
      raise "Derived jobs must override set_originator!"
   end

   def reuse_context(workflow_context)
      @logger = workflow_context.logger
      @status = workflow_context.status_object
   end

   # Start logging and update status, then launch into workflow
   #
   def perform(message)
      # If this job has been chained from another, the log will already exist and
      # should not be created
      if @logger.nil?
         log_file_path = File.join(JOB_LOG_DIR, "job_#{@status.id}.log")
         @logger = Logger.new(log_file_path)
         @logger.formatter = proc do |severity, datetime, progname, msg|
            "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} : #{severity} : #{msg}\n"
         end
      end

      # Flag job started running
      @logger.info "Start #{self.class.name} with params: #{message.to_json}"
      @status.started

      begin
         # all subclasses extend this method to define their job
         do_workflow(message)
      rescue Exception => e
         handle_wokflow_exception(e)
      end
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

   def handle_wokflow_exception(exception)
      # if this error was raised by on_error to end processing, the
      # status will have been bumped to failure. If status is still running
      # this error is the result of some other exception, call on_error to deal with it
      if @status.status == "running"
         on_error(exception)
      elsif @status.status == "failure"
         # if this has already failed, just keep passing the exception up the chain
         # to ensure all jobs get stopped and the head of the workflow is notified of the failure
         raise exception
      end
   end

   # Workflow is complete. Mark jobs status as done, update timestamps
   #
   def complete()
      if @status.status == 'running'
         @logger.info "Workflow #{self.class.name} has completed successfully"
         @status.finished
      end
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
      @status.update_attributes(:failures=>(@status.failures+1), :active_error=>true )
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
      #
      # For now, any errors terminate processing. Maybe relax this later
      #
      # if err.is_a? StandardError
      #    @logger.error err.message
      #    @logger.error err.backtrace.join("\n")
      #    @status.update_attribute(:failures, (@status.failures+1) )
      # else
         if err.is_a? Exception
            @logger.fatal err.message
            @logger.fatal err.backtrace.join("\n")
            @status.failed( err.message )
         else
            @logger.fatal err
            @logger.fatal caller.join("\n")
            @status.failed( err )
         end

         # Stop processing
         raise err
      # end
   end
end
