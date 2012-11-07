# Load the rails application
require File.expand_path('../application', __FILE__)

# Finalization Variables
PRODUCTION_MOUNT = "/digiserv-production"
MIGRATION_MOUNT = "/digiserv-migration"

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
MANUAL_ARCHIVE_IN_PROCESS_DIR_PRODUCTION = "#{PRODUCTION_MOUNT}/stornext_dropoff/in_process"
MANUAL_ARCHIVE_IN_PROCESS_DIR_MIGRATION = "#{MIGRATION_MOUNT}/stornext_dropoff/in_process"

DELIVERY_DIR = "/digiserv-delivery/patron"
DELIVERY_URL = "http://digiservdelivery.lib.virginia.edu/"

PRODUCTION_SCAN_SUBDIRECTORIES = ['01_from_archive', '10_raw', '40_first_QA', '50_create_metadata', '60_rescans_and_corrections', '70_second_qa', '80_final_qa', '90_make_deliverables', '101_archive', '100_finalization']
PRODUCTION_SCAN_DIR = "#{PRODUCTION_MOUNT}/scan"
PRODUCTION_METADATA_DIR = "#{PRODUCTION_MOUNT}/metadata"
PRODUCTION_SCAN_FROM_ARCHIVE_DIR = "#{PRODUCTION_SCAN_DIR}/01_from_archive"

# Batch migration variables
BATCH_MIGRATION_MOUNT = "/lib_content37/Rimage"
MANUAL_UPLOAD_TO_ARCHIVE_DIR_BATCH_MIGRATION = "#{BATCH_MIGRATION_MOUNT}/stornext_dropoff"
MANUAL_ARCHIVE_IN_PROCESS_DIR_BATCH_MIGRATION = "#{BATCH_MIGRATION_MOUNT}/stornext_dropoff/in_process"
BATCH_MIGRATION_DELETE_DIR_FROM_STORNEXT = "#{BATCH_MIGRATION_MOUNT}/ready_to_delete/from_stornext_manual_upload"

# Solr URL variables for interacting with sanctioned solr server.  Used in constructing solr records
# and in engaging lib/bibl_external_update
SOLR_PRODUCTION_NAME = "solrpowr.lib.virginia.edu"
SOLR_PRODUCTION_PORT = "8984"

# To prevent writing to production archive on Stornext from all but tracksys.production
# the default write directory will be Test.
ARCHIVE_WRITE_DIR = "/RMDS_archive/CheckSummed_archive"
ARCHIVE_READ_DIR = "/RMDS_archive/CheckSummed_archive"
TEI_ARCHIVE_DIR = "#{ARCHIVE_READ_DIR}/tracksys_tei_xml_depository"
XTF_DELIVERY_DIR = "/xtf_delivery/text"

# Will have to change this one when I figure out where to put the jp2k images
BASE_DESTINATION_PATH_DL  = "#{FINALIZATION_DIR_PRODUCTION}/30_process_deliverables" 

# VIRGO (Blacklight) URL for catalog linking in UI
VIRGO_URL = "http://search.lib.virginia.edu/catalog"

# Library homepage URL for request form footer
LIBRARY_URL = "http://www.lib.virginia.edu"

IVIEW_CATALOG_EXPORT_DIR = "/digiserv-production/administrative/EAD2iViewXML"

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
  }
Schema_locations = {
  'mods'=>'http://www.loc.gov/standards/mods/v3/mods-3-3.xsd',
  'mix'=>'http://www.loc.gov/standards/mix/mix20/mix20.xsd',
  'jhove'=>'http://hul.harvard.edu/ois/xml/xsd/jhove/jhove.xsd'
}
# Initialize the rails application
Tracksys::Application.initialize!
