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

# Original paths to production finalize/scan/delete directories
DROPOFF_DIR = "#{Settings.production_mount}/finalization/10_dropoff"
IN_PROCESS_DIR = "#{Settings.production_mount}/finalization/20_in_process"
PROCESS_DELIVERABLES_DIR = "#{Settings.production_mount}/finalization/30_process_deliverables"
ASSEMBLE_DELIVERY_DIR = "#{Settings.production_mount}/finalization/40_assemble_deliverables"

DELETE_DIR = "#{Settings.production_mount}/ready_to_delete"
DELETE_DIR_FROM_STORNEXT = "#{DELETE_DIR}/from_stornext_manual_upload"
DELETE_DIR_FROM_FINALIZATION = "#{DELETE_DIR}/from_finalization"
DELETE_DIR_DELIVERED_ORDERS = "#{DELETE_DIR}/delivered_orders"

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
