Delayed::Worker.max_run_time = 48.hours
Delayed::Worker.destroy_failed_jobs = true
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
