Tracksys::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Configure static asset server for tests with Cache-Control for performance
  config.serve_static_assets = true
  config.static_cache_control = "public, max-age=3600"

  # Log error messages when you accidentally call methods on nil
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  # Allow pass debug_assets=true as a query parameter to load pages with unpackaged assets
  config.assets.allow_debugging = true

  #  Fedora_apim_wsdl = 'http://tracksysdev.lib.virginia.edu:8080/fedora/wsdl?api=API-M'
  #  Fedora_apia_wsdl = 'http://tracksysdev.lib.virginia.edu:8080/fedora/wsdl?api=API-A'
  #  Fedora_username = 'fedoraAdmin'
  #  Fedora_password = 'fedoraAdmin'
  FEDORA_REST_URL = 'http://localhost:8080/fedora'
  SOLR_URL = "http://localhost:8983/solr/staging_solr"
  Fedora_username = 'fedoraAdmin'
  Fedora_password = 'fedoraAdmin'
  
  # TRACKSYS_URL = "http://tracksysdev.lib.virginia.edu/"
  #  TRACKSYS_URL_METADATA = "http://tracksysdev.lib.virginia.edu/metadata"
  #  DELIVERY_DIR = "/digiserv-delivery-test"
  #  TEI_ACCESS_URL = "http://xtf.lib.virginia.edu/xtf/view"
  
  # Set the number of threads dedicated to JP2K creation.
  #  NUM_JP2K_THREADS = 1
end
