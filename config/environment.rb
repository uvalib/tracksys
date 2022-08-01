# Load the Rails application.
require_relative 'application'

# VERSION INFO
#
TRACKSYS_VERSION = '6.10.8'

# Setup logger for all jobs processors
#
JOB_LOG_DIR = File.join(Rails.root,"log", "jobs")
if !Dir.exists? JOB_LOG_DIR
   FileUtils.mkdir_p JOB_LOG_DIR
end

# Convert settings into global constants
#
Settings = Figaro.env
ARCHIVE_DIR = Settings.archive_mount

# Users with special privileges
DEACCESSION_USERS = Settings.deaccession_users.blank? ? [] : Settings.deaccession_users.split(",")
PRESERVATION_USERS = Settings.preservation_users.blank? ? [] : Settings.preservation_users.split(",")

# Initialize the Rails application.
Rails.application.initialize!
