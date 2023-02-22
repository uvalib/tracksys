# Welcome to Tracksys

** This code is no longer maintained and is now a read-only archive. The service has been re-implemented here: **
https://github.com/uvalib/tracksys2

## Installation

### Ruby
* Install rbenv or RVM
* Install ruby 2.4.1
* If using rbenv: Run ```rbenv rehash```

### Other dependencies
* MySQL 5.6.27 (later version will not work!)
* imagemagick (http://www.imagemagick.org/script/binary-releases.php. Use brew for OSX)
* On OSX, image magick will also need Ghostscript and FreeType (brew install freetype;  brew install gs)
* Kakadu (No version for OSX; imagemagick used instead. www.kakadusoftware.com/)

### Rails
* gem install bundler
* cd /usr/local/projects
* git clone https://github.com/uvalib-dcs/tracksys.git
* cd tracksys
* git submodule init
* git submodule update
* bundle install --without development test (for production)
* If using rbenv: rbenv rehash # to run the executables of the newly installed gems.
* Create config/database.yml file with credentials for you MySQL install
* Copy config/application.yml-TEMPLATE to config/application.yml and update variables to match your environment
* rake db:create
* rake db:schema:load
* rake db:seed

NOTE: Spring is included as a gem to speed up the development environment, but it must not
      be used or installed on production. If it is, rails console will hang. Always use bundler commands
      like this: bundle install/update  --without development test.

