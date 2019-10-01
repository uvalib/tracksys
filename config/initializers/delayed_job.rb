Delayed::Worker.max_run_time = 48.hours
Delayed::Worker.destroy_failed_jobs = true
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

# QUIET LOGGING FOR QUERIES IN DEV MODE
ActiveRecord::Base.logger.level = 1 # or Logger::INFO

# from a not on gem site. Users having issues locking jobs should try this. Could help timeout
Delayed::Backend::ActiveRecord.configuration.reserve_sql_strategy = :default_sql
