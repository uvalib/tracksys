# Load the rails application
require File.expand_path('../application', __FILE__)

# VERSION INFO
#
TRACKSYS_VERSION = '4.1.0'

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
MIGRATION_MOUNT = Settings.migration_mount
DELIVERY_DIR = Settings.delivery_dir
DELIVERY_URL = Settings.delivery_url
ARCHIVE_DIR = Settings.archive_mount

FEDORA_REST_URL = Settings.fedora_rest_url
FEDORA_PROXY_URL = Settings.fedora_proxy_url
TRACKSYS_URL = Settings.tracksys_url
SAXON_URL = Settings.saxon_url
SAXON_PORT = Settings.saxon_port.to_i

FINALIZATION_DIR_PRODUCTION = "#{PRODUCTION_MOUNT}/finalization"
FINALIZATION_DIR_MIGRATION = "#{MIGRATION_MOUNT}/finalization"

FINALIZATION_DROPOFF_DIR_MIGRATION = "#{FINALIZATION_DIR_MIGRATION}/10_dropoff"
FINALIZATION_DROPOFF_DIR_PRODUCTION = "#{FINALIZATION_DIR_PRODUCTION}/10_dropoff"

IN_PROCESS_DIR = "#{FINALIZATION_DIR_PRODUCTION}/20_in_process"
PROCESS_DELIVERABLES_DIR = "#{FINALIZATION_DIR_PRODUCTION}/30_process_deliverables"
ASSEMBLE_DELIVERY_DIR = "#{FINALIZATION_DIR_PRODUCTION}/40_assemble_deliverables"
REVIEW_DIR = "#{FINALIZATION_DIR_PRODUCTION}/50_fail_checksum"
REPLACE_OR_ADD_MASTER_FILES_DIR = "#{FINALIZATION_DIR_PRODUCTION}/60_replace_master_files"

DELETE_DIR = "#{PRODUCTION_MOUNT}/ready_to_delete"
DELETE_DIR_FROM_STORNEXT = "#{DELETE_DIR}/from_stornext_manual_upload"
DELETE_DIR_FROM_FINALIZATION = "#{DELETE_DIR}/from_finalization"
DELETE_DIR_FROM_SCAN = "#{DELETE_DIR}/from_scan"
DELETE_DIR_DELIVERED_ORDERS = "#{DELETE_DIR}/delivered_orders"

MANUAL_UPLOAD_TO_ARCHIVE_DIR_PRODUCTION = "#{PRODUCTION_MOUNT}/stornext_dropoff"
MANUAL_UPLOAD_TO_ARCHIVE_DIR_MIGRATION = "#{MIGRATION_MOUNT}/stornext_dropoff"

PRODUCTION_SCAN_SUBDIRECTORIES = ['01_from_archive', '10_raw', '40_first_QA', '50_create_metadata', '60_rescans_and_corrections', '70_second_qa', '80_final_qa', '90_make_deliverables', '101_archive', '100_finalization']
PRODUCTION_SCAN_DIR = "#{PRODUCTION_MOUNT}/scan"
PRODUCTION_METADATA_DIR = "#{PRODUCTION_MOUNT}/metadata"
PRODUCTION_SCAN_FROM_ARCHIVE_DIR = "#{PRODUCTION_SCAN_DIR}/01_from_archive"

# Batch migration variables
BATCH_MIGRATION_MOUNT = Settings.batch_migration_mount
MANUAL_UPLOAD_TO_ARCHIVE_DIR_BATCH_MIGRATION = "#{BATCH_MIGRATION_MOUNT}/stornext_dropoff"
BATCH_MIGRATION_DELETE_DIR_FROM_STORNEXT = "#{BATCH_MIGRATION_MOUNT}/ready_to_delete/from_stornext_manual_upload"

# Solr URL variables for interacting with sanctioned solr server.  Used in constructing solr records
# and in engaging lib/bibl_external_update
SOLR_PRODUCTION_NAME = Settings.solr

# Will have to change this one when I figure out where to put the jp2k images
BASE_DESTINATION_PATH_DL  = "#{FINALIZATION_DIR_PRODUCTION}/30_process_deliverables"

# Kakadu JPEG2000 executable
KDU_COMPRESS= Settings.kdu_compress

# VIRGO (Blacklight) URL for catalog linking in UI
VIRGO_URL = Settings.virgo_url

# Library homepage URL for request form footer
LIBRARY_URL = Settings.library_url

IVIEW_CATALOG_EXPORT_DIR = "#{PRODUCTION_MOUNT}/administrative/EAD2iViewXML"

NUM_JP2K_THREADS = Settings.num_jp2k_threads.to_i

Fedora_namespaces = {
  'xsi'=>'http://www.w3.org/2001/XMLSchema-instance',
  'mets'=>'http://www.loc.gov/METS/',
  'mix'=>'http://www.loc.gov/mix/v20',
  'mods'=>'http://www.loc.gov/mods/v3',
  'textMD'=>'info:lc/xmlns/textMD-v3',
  'jhove'=>'http://hul.harvard.edu/ois/xml/ns/jhove',
  'xlink'=>'http://www.w3.org/1999/xlink',
  'xs'=>'http://www.w3.org/2001/XMLSchema',
  'dc'=>'http://purl.org/dc/elements/1.1/',
  'oai_dc'=>'http://www.openarchives.org/OAI/2.0/oai_dc/',
  'foxml' => 'info:fedora/fedora-system:def/foxml#',
  'fedora-model'=>'info:fedora/fedora-system:def/model#',
  'rdf'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
  'rdfs'=>'http://www.w3.org/2000/01/rdf-schema#',
  'rel'=>'info:fedora/fedora-system:def/relations-external#',
  'uva'=>'http://fedora.lib.virginia.edu/relationships#'
}
Fedora_content_models = {
  'fedora-generic'=>'fedora-system:FedoraObject-3.0',
  'jp2k'=>'djatoka:jp2CModel',
  'ead-component'=>'uva-lib:eadComponentCModel',
  'ead-collection'=>'uva-lib:eadCollectionCModel',
  'ead-item' => 'uva-lib:eadItemCModel',
  'placeholder' => 'uva-lib:descMetadataPlaceholderCModel',
  'mods34'=>'uva-lib:mods3.4CModel',
  'dpla-item' => 'uva-lib:DPLAItemCModel',
  'dpla-collection' => 'uva-lib:DPLACollectionCModel'
  }
Schema_locations = {
  'mods'=>'http://www.loc.gov/standards/mods/v3/mods-3-3.xsd',
  'mix'=>'http://www.loc.gov/standards/mix/mix20/mix20.xsd',
  'jhove'=>'http://hul.harvard.edu/ois/xml/xsd/jhove/jhove.xsd'
}
# Initialize the rails application
Tracksys::Application.initialize!
