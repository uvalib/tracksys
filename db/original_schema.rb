# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 0) do

  create_table "access_controls", :force => true do |t|
    t.integer  "access_level_id",  :default => 0,     :null => false
    t.string   "class_name_list"
    t.string   "action_name_list"
    t.boolean  "has_access",       :default => false, :null => false
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "access_controls", ["access_level_id"], :name => "access_level_id"

  create_table "access_levels", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "is_sysadmin", :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "access_levels", ["name"], :name => "index_access_levels_on_name", :unique => true

  create_table "agencies", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "is_billable",       :default => false, :null => false
    t.string   "last_name"
    t.string   "first_name"
    t.string   "address_1"
    t.string   "address_2"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "post_code"
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ancestry"
    t.string   "names_depth_cache"
  end

  add_index "agencies", ["name"], :name => "index_agencies_on_name", :unique => true
  add_index "agencies", ["ancestry"], :name => "index_agencies_on_ancestry"

  create_table "archives", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "archives", ["name"], :name => "index_archives_on_name", :unique => true

  create_table "automation_messages", :force => true do |t|
    t.integer  "unit_id"
    t.string   "pid"
    t.string   "app"
    t.string   "processor"
    t.string   "message_type"
    t.text     "message"
    t.string   "class_name"
    t.text     "backtrace"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_id"
    t.integer  "master_file_id"
    t.integer  "bibl_id"
    t.integer  "ead_ref_id"
    t.integer  "component_id"
    t.boolean  "active_error",   :default => false
  end

  add_index "automation_messages", ["unit_id"], :name => "index_automation_messages_on_unit_id"
  add_index "automation_messages", ["order_id"], :name => "index_automation_messages_on_order_id"
  add_index "automation_messages", ["processor"], :name => "index_automation_messages_on_processor"
  add_index "automation_messages", ["message_type"], :name => "index_automation_messages_on_message_type"
  add_index "automation_messages", ["active_error"], :name => "index_automation_messages_on_active_error"
  add_index "automation_messages", ["master_file_id"], :name => "index_automation_messages_on_master_file_id"
  add_index "automation_messages", ["bibl_id"], :name => "index_automation_messages_on_bibl_id"
  add_index "automation_messages", ["component_id"], :name => "index_automation_messages_on_component_id"
  add_index "automation_messages", ["ead_ref_id"], :name => "index_automation_messages_on_ead_ref_id"

  create_table "bibls", :force => true do |t|
    t.boolean  "is_approved",                                :default => false, :null => false
    t.boolean  "is_personal_item",                           :default => false, :null => false
    t.string   "resource_type"
    t.string   "genre"
    t.boolean  "is_manuscript",                              :default => false, :null => false
    t.boolean  "is_collection",                              :default => false, :null => false
    t.string   "title"
    t.text     "description"
    t.string   "series_title"
    t.string   "creator_name"
    t.string   "creator_name_type"
    t.string   "catalog_id"
    t.string   "title_control"
    t.string   "barcode"
    t.string   "call_number"
    t.integer  "copy"
    t.string   "volume"
    t.string   "location"
    t.string   "year"
    t.string   "year_type"
    t.datetime "date_external_update"
    t.string   "pid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_in_catalog",                              :default => false, :null => false
    t.string   "issue"
    t.text     "citation"
    t.text     "exemplar"
    t.integer  "parent_bibl_id",                             :default => 0,     :null => false
    t.text     "desc_metadata"
    t.text     "rels_ext"
    t.text     "solr",                 :limit => 2147483647
    t.text     "dc"
    t.string   "availability"
    t.text     "rels_int"
    t.integer  "content_model_id"
    t.boolean  "discoverability",                            :default => true
    t.integer  "indexing_scenario_id"
  end

  add_index "bibls", ["content_model_id"], :name => "content_model_id"
  add_index "bibls", ["indexing_scenario_id"], :name => "indexing_scenario_id"

  create_table "bibls_legacy_identifiers", :id => false, :force => true do |t|
    t.integer "legacy_identifier_id"
    t.integer "bibl_id"
  end

  add_index "bibls_legacy_identifiers", ["legacy_identifier_id"], :name => "legacy_identifier_id"
  add_index "bibls_legacy_identifiers", ["bibl_id"], :name => "bibl_id"

  create_table "billing_addresses", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "agency_id"
    t.string   "last_name"
    t.string   "first_name"
    t.string   "address_1"
    t.string   "address_2"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "post_code"
    t.string   "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "organization"
  end

  add_index "billing_addresses", ["customer_id"], :name => "index_billing_addresses_on_customer_id", :unique => true
  add_index "billing_addresses", ["agency_id"], :name => "index_billing_addresses_on_agency_id", :unique => true

  create_table "checkins", :force => true do |t|
    t.integer  "unit_id",         :default => 0, :null => false
    t.integer  "staff_member_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "checkins", ["unit_id"], :name => "unit_id"
  add_index "checkins", ["staff_member_id"], :name => "staff_member_id"

  create_table "component_types", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "component_types", ["name"], :name => "index_component_types_on_name", :unique => true

  create_table "components", :force => true do |t|
    t.integer  "component_type_id",                          :default => 0,     :null => false
    t.integer  "parent_component_id",                        :default => 0,     :null => false
    t.integer  "bibl_id",                                    :default => 0,     :null => false
    t.string   "title"
    t.string   "label"
    t.string   "date"
    t.text     "content_desc"
    t.string   "idno"
    t.string   "barcode"
    t.integer  "seq_number"
    t.string   "pid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "desc_metadata"
    t.text     "rels_ext"
    t.text     "solr",                 :limit => 2147483647
    t.text     "dc"
    t.string   "availability"
    t.text     "rels_int"
    t.boolean  "discoverability",                            :default => false
    t.integer  "indexing_scenario_id"
  end

  add_index "components", ["component_type_id"], :name => "component_type_id"
  add_index "components", ["bibl_id"], :name => "bibl_id"
  add_index "components", ["indexing_scenario_id"], :name => "indexing_scenario_id"

  create_table "content_models", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "content_models", ["name"], :name => "index_content_models_on_name", :unique => true

  create_table "countries", :force => true do |t|
    t.string  "name"
    t.string  "abbreviation", :limit => 2
    t.integer "display_sort",              :default => 0
  end

  add_index "countries", ["abbreviation"], :name => "index_countries_on_abbreviation", :unique => true

  create_table "customers", :force => true do |t|
    t.integer  "department_id"
    t.integer  "uva_status_id",          :default => 0, :null => false
    t.integer  "heard_about_service_id"
    t.string   "last_name"
    t.string   "first_name"
    t.string   "address_1"
    t.string   "address_2"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "post_code"
    t.string   "phone"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "organization"
  end

  add_index "customers", ["department_id"], :name => "department_id"
  add_index "customers", ["heard_about_service_id"], :name => "heard_about_service_id"
  add_index "customers", ["last_name"], :name => "index_customers_on_last_name"
  add_index "customers", ["first_name"], :name => "index_customers_on_first_name"
  add_index "customers", ["email"], :name => "index_customers_on_email"
  add_index "customers", ["uva_status_id"], :name => "index_customers_on_uva_status_id"

  create_table "datastreams", :force => true do |t|
    t.integer  "content_model_id", :default => 0, :null => false
    t.string   "name"
    t.string   "description"
    t.string   "format"
    t.integer  "resolution"
    t.string   "resolution_unit"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "datastreams", ["content_model_id"], :name => "content_model_id"

  create_table "deliverables", :force => true do |t|
    t.integer  "master_file_id",  :default => 0, :null => false
    t.integer  "datastream_id",   :default => 0, :null => false
    t.string   "filename"
    t.integer  "filesize"
    t.string   "format"
    t.integer  "resolution"
    t.string   "resolution_unit"
    t.string   "name_num"
    t.string   "snap_dragon_id"
    t.string   "color_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deliverables", ["master_file_id"], :name => "master_file_id"
  add_index "deliverables", ["datastream_id"], :name => "datastream_id"

  create_table "deliverables_delivery_methods", :id => false, :force => true do |t|
    t.integer "deliverable_id"
    t.integer "delivery_method_id"
  end

  add_index "deliverables_delivery_methods", ["deliverable_id"], :name => "deliverable_id"
  add_index "deliverables_delivery_methods", ["delivery_method_id"], :name => "delivery_method_id"

  create_table "delivery_methods", :force => true do |t|
    t.string   "label"
    t.string   "description"
    t.boolean  "is_internal_use_only", :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delivery_methods", ["label"], :name => "index_delivery_methods_on_label", :unique => true

  create_table "delivery_methods_orders", :id => false, :force => true do |t|
    t.integer "delivery_method_id"
    t.integer "order_id"
  end

  add_index "delivery_methods_orders", ["delivery_method_id"], :name => "delivery_method_id"
  add_index "delivery_methods_orders", ["order_id"], :name => "order_id"

  create_table "delivery_methods_units", :id => false, :force => true do |t|
    t.integer "delivery_method_id"
    t.integer "unit_id"
  end

  add_index "delivery_methods_units", ["delivery_method_id"], :name => "delivery_method_id"
  add_index "delivery_methods_units", ["unit_id"], :name => "unit_id"

  create_table "departments", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "departments", ["name"], :name => "index_departments_on_name", :unique => true

  create_table "dvd_delivery_locations", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "email_desc"
  end

  add_index "dvd_delivery_locations", ["name"], :name => "index_dvd_delivery_locations_on_name", :unique => true

  create_table "ead_refs", :force => true do |t|
    t.integer  "parent_ead_ref_id",                       :default => 0,     :null => false
    t.integer  "bibl_id",                                 :default => 0,     :null => false
    t.string   "ead_id_att"
    t.string   "level"
    t.string   "label"
    t.string   "date"
    t.text     "content_desc"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "desc_metadata"
    t.text     "rels_ext"
    t.text     "solr",              :limit => 2147483647
    t.text     "dc"
    t.string   "availability"
    t.text     "rels_int"
    t.boolean  "discoverability",                         :default => false
  end

  add_index "ead_refs", ["bibl_id"], :name => "bibl_id"

  create_table "ead_refs_master_files", :id => false, :force => true do |t|
    t.integer "ead_ref_id"
    t.integer "master_file_id"
  end

  add_index "ead_refs_master_files", ["ead_ref_id"], :name => "ead_ref_id"
  add_index "ead_refs_master_files", ["master_file_id"], :name => "master_file_id"

  create_table "heard_about_resources", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_approved",          :default => false, :null => false
    t.boolean  "is_internal_use_only", :default => false, :null => false
  end

  add_index "heard_about_resources", ["description"], :name => "index_heard_about_resources_on_description"

  create_table "heard_about_services", :force => true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_approved",          :default => false, :null => false
    t.boolean  "is_internal_use_only", :default => false, :null => false
  end

  add_index "heard_about_services", ["description"], :name => "index_heard_about_services_on_description"

  create_table "image_specs", :force => true do |t|
    t.integer  "unit_id",        :default => 0,     :null => false
    t.string   "color_type"
    t.string   "polarity_type"
    t.boolean  "is_disc_source", :default => false, :null => false
    t.integer  "disc_quantity"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "image_specs", ["unit_id"], :name => "index_image_specs_on_unit_id", :unique => true

  create_table "image_tech_meta", :force => true do |t|
    t.integer  "master_file_id",                                               :default => 0, :null => false
    t.string   "image_format"
    t.integer  "width"
    t.integer  "height"
    t.integer  "resolution"
    t.string   "resolution_unit"
    t.string   "color_space"
    t.integer  "depth"
    t.string   "compression"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "color_profile"
    t.text     "equipment"
    t.text     "software"
    t.text     "model"
    t.float    "exif_version"
    t.datetime "capture_date"
    t.integer  "iso"
    t.text     "exposure_bias"
    t.text     "exposure_time"
    t.text     "aperture"
    t.integer  "focal_length",    :limit => 10, :precision => 10, :scale => 0
  end

  add_index "image_tech_meta", ["master_file_id"], :name => "master_file_id"

  create_table "indexing_scenarios", :force => true do |t|
    t.string   "name"
    t.string   "pid"
    t.string   "datastream_name"
    t.string   "repository_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "intended_uses", :force => true do |t|
    t.string   "description"
    t.boolean  "is_internal_use_only", :default => false, :null => false
    t.boolean  "is_approved",          :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "intended_uses", ["description"], :name => "index_intended_uses_on_description"

  create_table "invoices", :force => true do |t|
    t.integer  "order_id",                                    :default => 0, :null => false
    t.datetime "date_invoice"
    t.text     "invoice_content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "invoice_number"
    t.integer  "fee_amount_paid"
    t.datetime "date_fee_paid"
    t.datetime "date_second_notice_sent"
    t.text     "transmittal_number"
    t.text     "notes"
    t.binary   "invoice_copy",            :limit => 16777215
  end

  add_index "invoices", ["order_id"], :name => "order_id"

  create_table "legacy_identifiers", :force => true do |t|
    t.string   "label"
    t.string   "description"
    t.string   "legacy_identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "legacy_identifiers", ["label"], :name => "index_legacy_identifiers_on_label"
  add_index "legacy_identifiers", ["legacy_identifier"], :name => "index_legacy_identifiers_on_legacy_identifier"

  create_table "legacy_identifiers_master_files", :id => false, :force => true do |t|
    t.integer "legacy_identifier_id"
    t.integer "master_file_id"
  end

  add_index "legacy_identifiers_master_files", ["legacy_identifier_id"], :name => "legacy_identifier_id"
  add_index "legacy_identifiers_master_files", ["master_file_id"], :name => "master_file_id"

  create_table "master_files", :force => true do |t|
    t.integer  "unit_id",                                    :default => 0,     :null => false
    t.integer  "component_id"
    t.integer  "equipment_id"
    t.string   "tech_meta_type"
    t.string   "filename"
    t.integer  "filesize"
    t.string   "name_num"
    t.datetime "date_archived"
    t.text     "staff_notes"
    t.text     "screen_preview"
    t.integer  "file_id_ref"
    t.string   "pid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "transcription_text"
    t.text     "desc_metadata"
    t.text     "rels_ext"
    t.text     "solr",                 :limit => 2147483647
    t.text     "dc"
    t.string   "availability"
    t.boolean  "locked_desc_metadata",                       :default => false
    t.text     "rels_int"
    t.boolean  "discoverability",                            :default => false
    t.string   "md5"
    t.integer  "indexing_scenario_id"
  end

  add_index "master_files", ["component_id"], :name => "component_id"
  add_index "master_files", ["equipment_id"], :name => "equipment_id"
  add_index "master_files", ["unit_id"], :name => "index_master_files_on_unit_id"
  add_index "master_files", ["tech_meta_type"], :name => "index_master_files_on_tech_meta_type"
  add_index "master_files", ["filename"], :name => "index_master_files_on_filename"
  add_index "master_files", ["name_num"], :name => "index_master_files_on_name_num"
  add_index "master_files", ["pid"], :name => "index_master_files_on_pid"
  add_index "master_files", ["indexing_scenario_id"], :name => "indexing_scenario_id"

  create_table "orders", :force => true do |t|
    t.integer  "customer_id",                                                      :default => 0,     :null => false
    t.integer  "agency_id"
    t.string   "order_status"
    t.text     "status_notes"
    t.boolean  "is_approved",                                                      :default => false, :null => false
    t.string   "order_title"
    t.datetime "date_request_submitted"
    t.datetime "date_order_approved"
    t.datetime "date_deferred"
    t.datetime "date_canceled"
    t.datetime "date_permissions_given"
    t.datetime "date_started"
    t.datetime "date_due"
    t.datetime "date_customer_notified"
    t.decimal  "fee_estimated",                      :precision => 7, :scale => 2
    t.decimal  "fee_actual",                         :precision => 7, :scale => 2
    t.string   "entered_by"
    t.text     "special_instructions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "staff_notes"
    t.integer  "dvd_delivery_location_id"
    t.text     "email"
    t.datetime "date_patron_deliverables_complete"
    t.datetime "date_archiving_complete"
    t.datetime "date_finalization_begun"
    t.datetime "date_fee_estimate_sent_to_customer"
  end

  add_index "orders", ["dvd_delivery_location_id"], :name => "dvd_delivery_location_id"
  add_index "orders", ["customer_id"], :name => "index_orders_on_customer_id"
  add_index "orders", ["agency_id"], :name => "index_orders_on_agency_id"
  add_index "orders", ["order_status"], :name => "index_orders_on_order_status"
  add_index "orders", ["date_request_submitted"], :name => "index_orders_on_date_request_submitted"
  add_index "orders", ["date_due"], :name => "index_orders_on_date_due"
  add_index "orders", ["date_archiving_complete"], :name => "index_orders_on_date_archiving_complete"
  add_index "orders", ["date_order_approved"], :name => "index_orders_on_date_order_approved"

  create_table "process_notification_refs", :force => true do |t|
    t.string  "computing_id"
    t.string  "process_name"
    t.integer "record_id"
    t.string  "record_status"
  end

  create_table "record_exports", :force => true do |t|
    t.string   "record_type"
    t.integer  "record_id"
    t.string   "computing_id"
    t.string   "export_format"
    t.string   "export_format_version"
    t.datetime "date_exported"
  end

  create_table "record_selection_refs", :force => true do |t|
    t.string  "computing_id"
    t.string  "record_selection_feature"
    t.integer "record_id"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "sql_reports", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.text     "sql"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "staff_members", :force => true do |t|
    t.integer  "access_level_id", :default => 0,     :null => false
    t.string   "computing_id"
    t.string   "last_name"
    t.string   "first_name"
    t.boolean  "is_active",       :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "staff_members", ["computing_id"], :name => "index_staff_members_on_computing_id", :unique => true
  add_index "staff_members", ["access_level_id"], :name => "access_level_id"

  create_table "states", :force => true do |t|
    t.string "name"
    t.string "abbreviation", :limit => 2
  end

  add_index "states", ["abbreviation"], :name => "index_states_on_abbreviation", :unique => true

  create_table "tasks", :force => true do |t|
    t.integer  "unit_id",         :default => 0, :null => false
    t.integer  "staff_member_id"
    t.integer  "workstation_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "task_status"
  end

  add_index "tasks", ["unit_id"], :name => "unit_id"
  add_index "tasks", ["staff_member_id"], :name => "staff_member_id"
  add_index "tasks", ["workstation_id"], :name => "workstation_id"

  create_table "text_tech_meta", :force => true do |t|
    t.integer  "master_file_id",              :default => 0, :null => false
    t.string   "text_format"
    t.string   "charset"
    t.string   "markup_basis"
    t.string   "markup_basis_version"
    t.string   "markup_language_name"
    t.string   "markup_language_version"
    t.string   "markup_language_schema_name"
    t.string   "markup_language_schema_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "root_element_name"
  end

  add_index "text_tech_meta", ["master_file_id"], :name => "master_file_id"

  create_table "unit_import_sources", :force => true do |t|
    t.integer  "unit_id",                                      :default => 0, :null => false
    t.string   "import_format_basis"
    t.string   "import_format_software"
    t.string   "import_format_version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "import_source",          :limit => 2147483647
  end

  add_index "unit_import_sources", ["unit_id"], :name => "unit_id"

  create_table "units", :force => true do |t|
    t.integer  "indexing_scenario_id"
    t.integer  "archive_id"
    t.integer  "order_id",                                       :default => 0,     :null => false
    t.integer  "bibl_id"
    t.integer  "content_model_id"
    t.integer  "heard_about_resource_id"
    t.integer  "vendor_batch_id"
    t.string   "unit_status"
    t.datetime "date_materials_received"
    t.datetime "date_materials_returned"
    t.integer  "unit_extent_estimated"
    t.integer  "unit_extent_actual"
    t.integer  "priority"
    t.text     "url"
    t.text     "special_instructions"
    t.string   "availability"
    t.string   "deliverable_format"
    t.string   "deliverable_resolution"
    t.string   "deliverable_resolution_unit"

    t.integer  "intended_use_id"
    t.boolean  "exclude_from_dl",                                :default => false, :null => false
    t.text     "staff_notes"
    t.string   "transcription_format"
    t.boolean  "fasttrack"
    t.integer  "use_right_id"
    t.datetime "date_queued_for_ingest"
    t.datetime "date_archived"
    t.datetime "date_patron_deliverables_ready"
    t.boolean  "include_in_dl",                                  :default => false
    t.datetime "date_dl_deliverables_ready"
    t.datetime "date_transcription_deliverables_sent_to_vendor"
    t.datetime "date_transcription_deliverables_ready"
    t.datetime "date_transcription_returned_from_vendor"
    t.datetime "date_cataloging_notification_sent"
    t.text     "transcription_vendor_invoice_num"
    t.string   "transcription_destination"
    t.boolean  "remove_watermark",                               :default => false
    t.boolean  "discoverability",                                :default => false
    
    t.boolean  "checked_out",                                    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "units", ["archive_id"], :name => "archive_id"
  add_index "units", ["content_model_id"], :name => "content_model_id"
  add_index "units", ["heard_about_resource_id"], :name => "heard_about_resource_id"
  add_index "units", ["vendor_batch_id"], :name => "vendor_batch_id"
  add_index "units", ["use_right_id"], :name => "use_right_id"
  add_index "units", ["order_id"], :name => "index_units_on_order_id"
  add_index "units", ["bibl_id"], :name => "index_units_on_bibl_id"
  add_index "units", ["date_archived"], :name => "index_units_on_date_archived"
  add_index "units", ["intended_use_id"], :name => "index_units_on_intended_use_id"
  add_index "units", ["indexing_scenario_id"], :name => "indexing_scenario_id"

  create_table "use_rights", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "use_rights", ["name"], :name => "index_use_rights_on_name", :unique => true

  create_table "uva_statuses", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "uva_statuses", ["name"], :name => "index_uva_statuses_on_name", :unique => true

  create_table "vendor_batches", :force => true do |t|
    t.integer  "vendor_id",   :default => 0, :null => false
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vendor_batches", ["vendor_id"], :name => "vendor_id"

  create_table "vendors", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "vendors", ["name"], :name => "index_vendors_on_name", :unique => true

  create_table "workstations", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "workstations", ["name"], :name => "index_workstations_on_name", :unique => true

  add_foreign_key "access_controls", "access_levels", :name => "access_controls_ibfk_1"

  add_foreign_key "bibls", "indexing_scenarios", :name => "bibls_ibfk_2"
  add_foreign_key "bibls", "content_models", :name => "bibls_ibfk_1"

  add_foreign_key "bibls_legacy_identifiers", "legacy_identifiers", :name => "bibls_legacy_identifiers_ibfk_1"
  add_foreign_key "bibls_legacy_identifiers", "bibls", :name => "bibls_legacy_identifiers_ibfk_2"

  add_foreign_key "billing_addresses", "customers", :name => "billing_addresses_ibfk_1"
  add_foreign_key "billing_addresses", "agencies", :name => "billing_addresses_ibfk_2"

  add_foreign_key "checkins", "units", :name => "checkins_ibfk_1"
  add_foreign_key "checkins", "staff_members", :name => "checkins_ibfk_2"

  add_foreign_key "components", "indexing_scenarios", :name => "components_ibfk_3"
  add_foreign_key "components", "component_types", :name => "components_ibfk_1"
  add_foreign_key "components", "bibls", :name => "components_ibfk_2"

  add_foreign_key "customers", "departments", :name => "customers_ibfk_1"
  add_foreign_key "customers", "uva_statuses", :name => "customers_ibfk_2"
  add_foreign_key "customers", "heard_about_services", :name => "customers_ibfk_3"

  add_foreign_key "datastreams", "content_models", :name => "datastreams_ibfk_1"

  add_foreign_key "deliverables", "master_files", :name => "deliverables_ibfk_1"
  add_foreign_key "deliverables", "datastreams", :name => "deliverables_ibfk_2"

  add_foreign_key "deliverables_delivery_methods", "deliverables", :name => "deliverables_delivery_methods_ibfk_1"
  add_foreign_key "deliverables_delivery_methods", "delivery_methods", :name => "deliverables_delivery_methods_ibfk_2"

  add_foreign_key "delivery_methods_orders", "delivery_methods", :name => "delivery_methods_orders_ibfk_1"
  add_foreign_key "delivery_methods_orders", "orders", :name => "delivery_methods_orders_ibfk_2"

  add_foreign_key "delivery_methods_units", "delivery_methods", :name => "delivery_methods_units_ibfk_1"
  add_foreign_key "delivery_methods_units", "units", :name => "delivery_methods_units_ibfk_2"

  add_foreign_key "ead_refs", "bibls", :name => "ead_refs_ibfk_1"

  add_foreign_key "ead_refs_master_files", "ead_refs", :name => "ead_refs_master_files_ibfk_1"
  add_foreign_key "ead_refs_master_files", "master_files", :name => "ead_refs_master_files_ibfk_2"

  add_foreign_key "image_specs", "units", :name => "image_specs_ibfk_1"

  add_foreign_key "image_tech_meta", "master_files", :name => "image_tech_meta_ibfk_1"

  add_foreign_key "invoices", "orders", :name => "invoices_ibfk_1"

  add_foreign_key "legacy_identifiers_master_files", "legacy_identifiers", :name => "legacy_identifiers_master_files_ibfk_1"
  add_foreign_key "legacy_identifiers_master_files", "master_files", :name => "legacy_identifiers_master_files_ibfk_2"

  add_foreign_key "master_files", "indexing_scenarios", :name => "master_files_ibfk_3"
  add_foreign_key "master_files", "units", :name => "master_files_ibfk_1"
  add_foreign_key "master_files", "components", :name => "master_files_ibfk_2"

  add_foreign_key "orders", "customers", :name => "orders_ibfk_1"
  add_foreign_key "orders", "agencies", :name => "orders_ibfk_2"
  add_foreign_key "orders", "dvd_delivery_locations", :name => "orders_ibfk_3"

  add_foreign_key "staff_members", "access_levels", :name => "staff_members_ibfk_1"

  add_foreign_key "tasks", "units", :name => "tasks_ibfk_1"
  add_foreign_key "tasks", "staff_members", :name => "tasks_ibfk_2"
  add_foreign_key "tasks", "workstations", :name => "tasks_ibfk_3"

  add_foreign_key "text_tech_meta", "master_files", :name => "text_tech_meta_ibfk_1"

  add_foreign_key "unit_import_sources", "units", :name => "unit_import_sources_ibfk_1"

  add_foreign_key "units", "orders", :name => "units_ibfk_1"
  add_foreign_key "units", "bibls", :name => "units_ibfk_2"
  add_foreign_key "units", "archives", :name => "units_ibfk_3"
  add_foreign_key "units", "content_models", :name => "units_ibfk_4"
  add_foreign_key "units", "heard_about_resources", :name => "units_ibfk_5"
  add_foreign_key "units", "vendor_batches", :name => "units_ibfk_6"
  add_foreign_key "units", "intended_uses", :name => "units_ibfk_7"
  add_foreign_key "units", "use_rights", :name => "units_ibfk_8"
  add_foreign_key "units", "indexing_scenarios", :name => "units_ibfk_9"

  add_foreign_key "vendor_batches", "vendors", :name => "vendor_batches_ibfk_1"

end
