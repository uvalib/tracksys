#!/bin/bash
source "/usr/local/rvm/scripts/rvm"
RAILS_ENV=production script/delayed_job -n8 stop