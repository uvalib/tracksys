#!/bin/bash
RAILS_ENV=production script/delayed_job -n 4 start
