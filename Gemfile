source 'http://rubygems.org'

gem 'rails', '3.2.2'

# Needed to resolve incompatability with Fedora 12+
gem 'execjs'
gem 'therubyracer'

gem 'hydraulics', :path => '../hydraulics'
gem 'activeadmin', '0.4.3'
gem 'sass-rails'
gem 'meta_search',    '>= 1.1.0.pre'

gem 'sqlite3'
gem 'json'
gem 'validates_timeliness'
gem 'annotate', '2.4.1.beta1'
gem 'mysql2'
gem 'foreigner'
gem 'ancestry'
gem 'activemessaging', :git => 'git://github.com/kookster/activemessaging.git'
gem "daemons"
gem "stomp"
#gem "memcache-client"
gem "rmagick"
gem 'exifr'
gem 'rest-client'
gem 'solr-ruby'
gem 'spreadsheet'

gem "rspec-rails", :group => [:test, :development]
group :test do
  gem "factory_girl_rails"
  gem "capybara"
  gem "guard-rspec"
end

group :production, :test do
  gem "devise_ldap_authenticatable"
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
end

gem 'jquery-rails'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'

