class BaseJob
   # Execute the job asynchronously. Always the start of a workflow.
   # The ID of the delayed job is returned so status can be polled
   #
   def self.exec(message={})
      job = self.new()
      job_id = job.prepare(message)
      job.delay.perform(message)
      return job_id
   end

   # Execute the job synchronously. If the job context is set, this is part of
   # a larger workflow.
   #
   def self.exec_now(message={}, workflow_context = nil)
      job = self.new()

      # setup status and logging using context if available, then perform the job
      job.prepare(message, workflow_context)
      job.perform(message)

      # nil context means this is the start point of a workflow
      # once we are out of the perform, the workflow is complete.
      # Update the status object
      if workflow_context.nil?
         job.complete()
      end
   end

   # Prepare the job status and logging for this job.
   # If this job has been chained from another, the context will be
   # non-nil. In this case, re-use the logger and status from the
   # preceeding job
   #
   def prepare(message, workflow_context=nil)
      if !workflow_context.nil?
         @logger = workflow_context.logger
         @status = workflow_context.status_object
      else
         @status = JobStatus.create(name: self.class.name)
         set_originator(message)
         originator = @status.originator

         # Log initial job params so they will always appear in job log - even before start
         # IMPORTANT:
         # logger needs to be created before job starts, and again after it starts
         # not sure why, but if it is created prior and saved as member variable
         # the job does not run, and produces no errors nor logs
         create_logger(@status.id).info "Schedule #{self.class.name} with params: #{message.to_json}"
      end
      return @status.id
   end

   # helper to create job logger
   #
   def create_logger(job_id)
      log_file_path = File.join(JOB_LOG_DIR, "job_#{job_id}.log")
      if File.exists? log_file_path
         FileUtils.rm(log_file_path)
      end
      logger = Logger.new(log_file_path)
      logger.formatter = proc do |severity, datetime, progname, msg|
         "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} : #{severity} : #{msg}\n"
      end
      return logger
   end

   # Set the originiator of this job request. Default is no originator
   #
   def set_originator(message)
      # no originator. For jobs that are only called from within other
      # jobs, there is no need to override this method.
   end

   # Start logging and update status, then launch into workflow
   #
   def perform(message)
      # If this job has been chained from another, the log will already exist and
      # should not be created
      if @logger.nil?
         @logger = create_logger(@status.id)
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

   # Workflow is complete. Mark jobs status as done, update timestamps
   #
   def complete()
      if @status.status == 'running'
         @logger.info "Workflow #{self.class.name} has completed."
         @status.finished
      end
   end

   #
   # Job Logging Methods
   #
   def on_success(message)
      @logger.info message
   end

   # Log a warning message and keep processing
   #
   def on_failure(message)
      @status.update_attributes(:failures=>(@status.failures+1) )
      @logger.error message
   end

   # This method is called whenever an exception is raised within on_message.
   # Handles StandardError exceptions and keeps processing. Other exceptions
   # are raised, terminating processing.
   #
   def on_error(err)
      if err.is_a? Exception
         @status.failed( err.message )
         @logger.fatal err.message
         @logger.fatal err.backtrace.join("\n")
      else
         @status.failed( err )
         @logger.fatal err
      end

      # Stop processing
      raise err
   end
end
