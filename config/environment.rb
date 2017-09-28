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
PRODUCTION_MOUNT = Settings.production_mount
DELIVERY_DIR = Settings.delivery_dir
DELIVERY_URL = Settings.delivery_url
ARCHIVE_DIR = Settings.archive_mount

XML_DROPOFF_DIR = "#{PRODUCTION_MOUNT}/xml_metadata/dropoff"
XML_PICKUP_DIR = "#{PRODUCTION_MOUNT}/xml_metadata/pickup"

FINALIZATION_DIR_PRODUCTION = "#{PRODUCTION_MOUNT}/finalization"
FINALIZATION_DROPOFF_DIR_PRODUCTION = "#{FINALIZATION_DIR_PRODUCTION}/10_dropoff"

IN_PROCESS_DIR = "#{FINALIZATION_DIR_PRODUCTION}/20_in_process"
PROCESS_DELIVERABLES_DIR = "#{FINALIZATION_DIR_PRODUCTION}/30_process_deliverables"
ASSEMBLE_DELIVERY_DIR = "#{FINALIZATION_DIR_PRODUCTION}/40_assemble_deliverables"

DELETE_DIR = "#{PRODUCTION_MOUNT}/ready_to_delete"
DELETE_DIR_FROM_STORNEXT = "#{DELETE_DIR}/from_stornext_manual_upload"
DELETE_DIR_FROM_FINALIZATION = "#{DELETE_DIR}/from_finalization"
DELETE_DIR_FROM_SCAN = "#{DELETE_DIR}/from_scan"
DELETE_DIR_DELIVERED_ORDERS = "#{DELETE_DIR}/delivered_orders"

MANUAL_UPLOAD_TO_ARCHIVE_DIR_PRODUCTION = "#{PRODUCTION_MOUNT}/stornext_dropoff"

PRODUCTION_SCAN_SUBDIRECTORIES = ['01_from_archive', '10_raw', '40_first_QA', '50_create_metadata', '60_rescans_and_corrections', '70_second_qa', '80_final_qa', '90_make_deliverables', '101_archive', '100_finalization']
PRODUCTION_SCAN_DIR = "#{PRODUCTION_MOUNT}/scan"
PRODUCTION_SCAN_FROM_ARCHIVE_DIR = "#{PRODUCTION_SCAN_DIR}/01_from_archive"

# Kakadu JPEG2000 executable
KDU_COMPRESS= Settings.kdu_compress

# VIRGO (Blacklight) URL for catalog linking in UI
VIRGO_URL = Settings.virgo_url

# Library homepage URL for request form footer
LIBRARY_URL = Settings.library_url

IVIEW_CATALOG_EXPORT_DIR = "#{PRODUCTION_MOUNT}/administrative/EAD2iViewXML"

NUM_JP2K_THREADS = Settings.num_jp2k_threads.to_i

DEACCESSION_USERS = Settings.deaccession_users.blank? ? [] : Settings.deaccession_users.split(",")

# Initialize the Rails application.
Rails.application.initialize!
