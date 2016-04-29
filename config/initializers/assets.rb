# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w( request.css )
Rails.application.config.assets.precompile += %w( request.js )
Rails.application.config.assets.precompile += %w( printable.css )
Rails.application.config.assets.precompile += %w( email.css )
Rails.application.config.assets.precompile += %w( active_admin.js )
# active_admin.css active_admin.js request.css request.js email.css printable.css

# Enable the asset pipeline
# config.assets.enabled = true
# config.assets.paths << "#{config.root}/assets/images/request_form"
# config.assets.paths << "#{config.root}/assets/stylesheets/request"
#
# # Version of your assets, change this if you want to expire all your assets
# config.assets.version = '1.0'
