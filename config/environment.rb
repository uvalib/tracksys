# Load the Rails application.
require_relative 'application'

# VERSION INFO
#
TRACKSYS_VERSION = '5.2.0'

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

# same for all jobs
MANUAL_UPLOAD_TO_ARCHIVE_DIR_PRODUCTION = "#{Settings.production_mount}/stornext_dropoff"

# Original paths to production finalize/scan/delete directories
FINALIZATION_DIR = "#{Settings.production_mount}/finalization"
DROPOFF_DIR = "#{FINALIZATION_DIR}/10_dropoff"
IN_PROCESS_DIR = "#{FINALIZATION_DIR}/20_in_process"
PROCESS_DELIVERABLES_DIR = "#{FINALIZATION_DIR}/30_process_deliverables"
ASSEMBLE_DELIVERY_DIR = "#{FINALIZATION_DIR}/40_assemble_deliverables"

DELETE_DIR = "#{Settings.production_mount}/ready_to_delete"
DELETE_DIR_FROM_STORNEXT = "#{DELETE_DIR}/from_stornext_manual_upload"
DELETE_DIR_FROM_FINALIZATION = "#{DELETE_DIR}/from_finalization"
DELETE_DIR_DELIVERED_ORDERS = "#{DELETE_DIR}/delivered_orders"

PRODUCTION_SCAN_DIR = "#{Settings.production_mount}/scan"
PRODUCTION_SCAN_FROM_ARCHIVE_DIR = "#{PRODUCTION_SCAN_DIR}/01_from_archive"

# Kakadu JPEG2000 executable
KDU_COMPRESS= Settings.kdu_compress

# VIRGO (Blacklight) URL for catalog linking in UI
VIRGO_URL = Settings.virgo_url

# Library homepage URL for request form footer
LIBRARY_URL = Settings.library_url

IVIEW_CATALOG_EXPORT_DIR = "#{Settings.production_mount}/administrative/EAD2iViewXML"

NUM_JP2K_THREADS = Settings.num_jp2k_threads.to_i

DEACCESSION_USERS = Settings.deaccession_users.blank? ? [] : Settings.deaccession_users.split(",")

# Initialize the Rails application.
Rails.application.initialize!
