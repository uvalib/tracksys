Tracksys::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.

  # This has to be set to true if we want to expire pages and actions.
  config.cache_classes = false
  # Setting this to null avoids annoying database timeouts
  config.cache_store = :null_store

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Provide path for CSS for Roadie.
  config.action_mailer.default_url_options = {:host => 'tracksystest.lib.virginia.edu'}

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
 #config.action_controller.perform_caching = true
# config.cache_store = :mem_cache_store, { :namespace => 'master_files' }

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

end
