# Welcome to Tracksys

## Installation

### Ruby
* Install rbenv
* Install ruby 1.9.3-p448
* Run ```rbenv rehash```

### Rails

```
rbenv 1.9.3-p448
gem install bundle
cd /usr/local/projects
git clone https://github.com/uvalib-dcs/hydraulics.git
git clone https://github.com/uvalib-dcs/tracksys.git
cd tracksys
bundle
rbenv rehash # to run the executables of the newly installed gems.
rake db:setup
```
