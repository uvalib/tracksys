# Welcome to Tracksys

## Installation

### Ruby
* Install rbenv or RVM
* Install ruby 2.2.4
* If using rbenv: Run ```rbenv rehash```

### Other dependencies
* MySQL 5.6.27 (later version will not work!)
* imagemagick (http://www.imagemagick.org/script/binary-releases.php. Use brew for OSX)
* On OSX, image magick will also need Ghostscript and FreeType (brew install freetype;  brew install gs)
* Kakadu (No version for OSX; imagemagick used instead. www.kakadusoftware.com/)

### Rails
* If using rbenv: rbenv 1.9.3-p448
* gem install bundler -v1.3.5  (later version will not work)
* cd /usr/local/projects
* git clone https://github.com/uvalib-dcs/tracksys.git
* cd tracksys
* git submodule init
* git submodule update
* bundle install
* If using rbenv: rbenv rehash # to run the executables of the newly installed gems.
* Create config/database.yml file with credentials for you MySQL install
* Copy config/application.yml-TEMPLATE to config/application.yml and update variables to match your environment
* rake db:create
* rake db:migrate
* A simple set of starter sql data can be found in db/ts_daily_progress_min.sql; import it into your DB.
