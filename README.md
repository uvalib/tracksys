# Welcome to Tracksys

## Installation

### Ruby
* Install rbenv or RVM
* Install ruby 2.2.4
* If using rbenv: Run ```rbenv rehash```

### Other dependencies
* MySQL 5.6.27 (later version will not work!)
* imagemagick (http://www.imagemagick.org/script/binary-releases.php. Use brew for OSX)
* Kakadu (No version for OSX; imagemagick used instead. www.kakadusoftware.com/)
* ActiveMQ version 5.8.0 (http://activemq.apache.org/activemq-580-release.html)

### ActiveMQ
Before starting ActiveMQ, you need to enable the Stomp transport. Navigate to ./conf and open activemq.xml.
Find the TransportConnectors section and uncomment or add the following line:
<transportConnector name="stomp" uri="stomp://0.0.0.0:61613?maximumConnections=1000&amp;wireformat.maxFram     eSize=104857600"/>

Once this is done, you can start the server with ./bin/activemq start. Point your browser at:
http://127.0.0.1:8161/admin/
u: admin, p: admin 
to verify that it is working. 

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
* rake db:create
* rake db:migrate
* A simple set of starter sql data can be found in db/ts_daily_progress_min.sql; import it into your DB.

### Startign the server
The main server can me run as you would expect: rails s

This will get you the UI and basic browsing/editing functionality, but none of the processes will work. To make
this happen, the pollers must be started. There is a script for this. From the root of your install, run:
./script/start_pollers.sh.

You will see a list of pollers getting started. Once the script terminates, all are running and Tracksys 
should be fully functional.

If you need to stop the pollers, run: ./script/poller stop
