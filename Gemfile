source 'http://rubygems.org'

gem 'rails', '~> 5.2.3'
gem 'uglifier', '>= 1.3.0'
gem 'sass-rails', '~> 6.0'

# Reduces boot times through caching; required in config/boot.rb
# gem 'bootsnap', '>= 1.1.0', require: false

gem "nokogiri", ">= 1.10.8"

gem 'activeadmin', '~> 2.6.1'
gem 'ffi', '~> 1.15.0'

#gem 'passenger', '5.1.5'
gem 'figaro'

gem 'turnout'           # Maintence page

gem 'annotate'
gem 'mysql2'
gem 'ancestry'
gem 'diffy'             # to diff XML metadata changes

# gems for APTrust submission
gem 'aws-sdk-s3', '~> 1'

gem 'whenever', :require => false   # to age off job status records
gem 'rest-client'

gem 'jquery-rails'
gem "chosen-rails", "1.8.2"
gem "country-select", "~> 1.2"

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
