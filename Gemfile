source 'http://rubygems.org'

gem 'rails', '5.2.1'
gem 'uglifier', '>= 1.3.0'
gem 'sass-rails', '~> 5.0'
#gem 'sassc-rails'

# Reduces boot times through caching; required in config/boot.rb
# gem 'bootsnap', '>= 1.1.0', require: false

gem 'activeadmin', '~> 1.0'
gem 'ffi', '~> 1.9.24'

gem 'passenger', '5.1.5'
gem 'figaro'
gem 'exception_notification'
gem "puma"

gem 'turnout'           # Maintence page

gem 'annotate'
gem 'mysql2'  
gem 'redis'             # for cache of AS session tokens  
gem 'ancestry'
gem 'diffy'             # to diff XML metadata changes

# gems for APTrust submission
gem 'aws-sdk-s3', '~> 1'

gem 'delayed_job_active_record'
gem 'daemons'

# For publishing QDC
gem 'git'

# for patron request forms
gem 'bootstrap-datepicker-rails'

gem 'whenever', :require => false   # to age off job status records
gem "mini_magick"
gem 'rest-client'
gem 'prawn'
gem 'prawn-table'
gem 'country-select'

gem 'jquery-rails'
gem "chosen-rails", "1.8.2"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
#  gem 'rb-readline'  # use this if there are dl_open problems with readline on osx
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
#  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
#  gem 'spring'
#  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'pry-rails'
end
