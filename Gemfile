source 'http://rubygems.org'

gem 'rails'

# Needed to resolve incompatability with Fedora 12+
gem 'execjs'
gem 'therubyracer'

gem 'hydraulics', :path => '../hydraulics'
#gem 'hydraulics', :git => 'git://github.com/acurley/hydraulics.git'
gem 'activeadmin', :git => 'git://github.com/gregbell/active_admin.git'
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
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end

gem 'jquery-rails'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'

