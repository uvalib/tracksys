#!/bin/bash
RAILS_ENV=production script/delayed_job -n8 status