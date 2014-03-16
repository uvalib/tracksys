#!/bin/bash

# a simple script to do the three restart commands
# in a reasonable sequence
# please only run from Rails root dir, as correct user 

PROGNAME=$0
TRACKSYS_ROOT=/usr/local/projects/tracksys
status=0

stop_pollers () {
  status=eval $TRACKSYS_ROOT/script/poller stop
  echo "stop_pollers exit status: $status"
}
restart_rails () {
  status=eval touch $TRACKSYS_ROOT/tmp/restart.txt
  echo "restart_rails exit status: $status"
}
start_pollers () {
  status=eval $TRACKSYS_ROOT/tmp/start_application.sh
  echo "start_pollers exit status: $status"
}
query_user () {
  read -p "Run command $PROGNAME? [yN] " answer
  if [[ $answer =~ [yY] ]] ; then
    # run the command
    echo "OK, I will stop all pollers, restart Rails, and start all pollers."
    sleep 3
    now=$( date )
    echo "Global restart of Tracksys at $now"
    stop_pollers
    restart_rails
    start_pollers
  else 
    exit 0
  fi
}

# main
query_user
exit $status
