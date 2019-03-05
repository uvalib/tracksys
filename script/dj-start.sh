#!/bin/bash
# If present, source RVM so it is availble to this script
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  source "/usr/local/rvm/scripts/rvm"
fi
RAILS_ENV=production script/delayed_job -n8 start