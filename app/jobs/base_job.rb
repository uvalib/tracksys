class BaseJob
   # Execute the job asynchronously. Always the start of a workflow.
   # The ID of the delayed job is returned so status can be polled
   #
   def self.exec(message={})
      # create the job instance and a status tracker. Save it status ID
      # in the message params so in can be re-used when the job processing starts
      job = self.new()
      job.status = JobStatus.create(name: job.class.name)
      job.set_originator(message)
      job.delay.perform(message)
      return job.status.id
   end

   # Execute the job synchronously. If the job context is set, this is part of
   # a larger workflow.
   #
   def self.exec_now(message={}, workflow_context = nil)
      job = self.new()
      job.perform(message, workflow_context)

      # nil context means this is the start point of a workflow
      # once we are out of the perform, the workflow is complete.
      # Update the status object
      if workflow_context.nil?
         job.complete()
      end
   end

   # Start logging and update status, then launch into workflow
   #
   def perform(message, workflow_context=nil)
      # Setup logging and job status onject. These may be
      # created or reused from data in context or message params
      prepare(message, workflow_context)

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

   # Prepare the job status and logging for this job.
   # If this job has been chained from another, the context will be
   # non-nil. In this case, re-use the logger and status from the
   # preceeding job
   #
   def prepare(message, workflow_context=nil)
      if !workflow_context.nil?
         @logger = workflow_context.logger
         @status = workflow_context.status
      else
         @logger = @status.create_logger()
         if @status.nil?
            @status = JobStatus.create(name: self.class.name)
            set_originator(message)
         end
      end
   end

   # Set the originiator of this job request. Default is no originator
   #
   def set_originator(message)
      # no originator. For jobs that are only called from within other
      # jobs, there is no need to override this method.
   end

   def handle_wokflow_exception(exception)
      # if this error was raised by fatal_error to end processing, the
      # status will have been bumped to failure. If status is still running
      # this error is the result of some other exception, call fatal_error to deal with it
      if @status.status == "running"
         fatal_error(exception)
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
   def status
      @status
   end
   def status=(value)
      @status = value
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

   # Log a warning message and track the total
   #
   def log_failure(message)
      @status.update_attributes(:failures=>(@status.failures+1) )
      @logger.error message
   end

   # This method is called whenever an exception is raised within on_message.
   # Handles StandardError exceptions and keeps processing. Other exceptions
   # are raised, terminating processing.
   #
   def fatal_error(err)
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