Tracksys::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.

  # This has to be set to true if we want to expire pages and actions.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

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

#  Fedora_apim_wsdl = 'http://tracksysdev.lib.virginia.edu:8080/fedora/wsdl?api=API-M'
#  Fedora_apia_wsdl = 'http://tracksysdev.lib.virginia.edu:8080/fedora/wsdl?api=API-A'
#  Fedora_username = 'fedoraAdmin'
#  Fedora_password = 'fedoraAdmin'
 FEDORA_REST_URL = 'http://localhost:8080/fedora'
 SOLR_URL = "http://localhost:8983/solr/staging_solr"
 Fedora_username = 'fedoraAdmin'
 Fedora_password = 'fedoraAdmin'
  
 TRACKSYS_URL = "http://tracksysdev.lib.virginia.edu/"
#  TRACKSYS_URL_METADATA = "http://tracksysdev.lib.virginia.edu/metadata"
#  DELIVERY_DIR = "/digiserv-delivery-test"
#  TEI_ACCESS_URL = "http://xtf.lib.virginia.edu/xtf/view"
  
  # Set the number of threads dedicated to JP2K creation.
#  NUM_JP2K_THREADS = 1

config.after_initialize do
  PRODUCTION_MOUNT = "/Volumes/digiserv-production"
  MIGRATION_MOUNT = "/Volumes/digiserv-migration"

  ADMINISTRATIVE_DIR_PRODUCTION = "#{PRODUCTION_MOUNT}/administrative"
  IVIEW_CATALOG_EXPORT_DIR = "#{ADMINISTRATIVE_DIR_PRODUCTION}/EAD2iViewXML"
end

end
