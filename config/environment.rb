# Load the Rails application.
require_relative 'application'

# VERSION INFO
#
TRACKSYS_VERSION = '5.43.0'

# Setup logger for all jobs processors
#
JOB_LOG_DIR = File.join(Rails.root,"log", "jobs")
if !Dir.exists? JOB_LOG_DIR
   FileUtils.mkdir_p JOB_LOG_DIR
end

# Convert settings into global constants
#
Settings = Figaro.env
DELIVERY_DIR = Settings.delivery_dir
DELIVERY_URL = Settings.delivery_url
ARCHIVE_DIR = Settings.archive_mount

# Kakadu settings
KDU_COMPRESS= Settings.kdu_compress
NUM_JP2K_THREADS = Settings.num_jp2k_threads.to_i

# Users with special privileges
DEACCESSION_USERS = Settings.deaccession_users.blank? ? [] : Settings.deaccession_users.split(",")
PRESERVATION_USERS = Settings.preservation_users.blank? ? [] : Settings.preservation_users.split(",")

# Initialize the Rails application.
Rails.application.initialize!
