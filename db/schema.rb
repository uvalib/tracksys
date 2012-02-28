# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110928202329) do

  create_table "academic_statuses", :force => true do |t|
    t.datetime "created_at"
    t.integer  "customers_count", :default => 0
    t.string   "name"
    t.datetime "updated_at"
  end

  add_index "academic_statuses", ["name"], :name => "index_academic_statuses_on_name", :unique => true

  create_table "active_admin_comments", :force => true do |t|
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.string   "namespace"
    t.integer  "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "admin_users", :force => true do |t|
    t.datetime "created_at",                                            :null => false
    t.datetime "current_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
    t.datetime "last_sign_in_at"
    t.string   "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string   "reset_password_token"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "updated_at",                                            :null => false
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "agencies", :force => true do |t|
    t.string   "address_1"
    t.string   "address_2"
    t.string   "ancestry"
    t.string   "city"
    t.string   "country"
    t.datetime "created_at"
    t.string   "description"
    t.string   "first_name"
    t.boolean  "is_billable",       :default => false, :null => false
    t.string   "last_name"
    t.string   "name"
    t.string   "names_depth_cache"
    t.integer  "orders_count",      :default => 0
    t.string   "phone"
    t.string   "post_code"
    t.string   "state"
    t.datetime "updated_at"
  end

  add_index "agencies", ["ancestry"], :name => "index_agencies_on_ancestry"
  add_index "agencies", ["name"], :name => "index_agencies_on_name", :unique => true

  create_table "archives", :force => true do |t|
    t.datetime "created_at"
    t.string   "description"
    t.string   "name"
    t.integer  "units_count", :default => 0
    t.datetime "updated_at"
  end

  add_index "archives", ["name"], :name => "index_archives_on_name", :unique => true

  create_table "automation_messages", :force => true do |t|
    t.boolean  "active_error",   :default => false, :null => false
    t.string   "app"
    t.text     "backtrace"
    t.integer  "bibl_id"
    t.string   "class_name"
    t.integer  "component_id"
    t.datetime "created_at"
    t.integer  "master_file_id"
    t.string   "message"
    t.string   "message_type"
    t.integer  "order_id"
    t.string   "pid"
    t.string   "processor"
    t.integer  "unit_id"
    t.datetime "updated_at"
    t.string   "workflow_type"
  end

  add_index "automation_messages", ["active_error"], :name => "index_automation_messages_on_active_error"
  add_index "automation_messages", ["bibl_id"], :name => "index_automation_messages_on_bibl_id"
  add_index "automation_messages", ["component_id"], :name => "index_automation_messages_on_component_id"
  add_index "automation_messages", ["master_file_id"], :name => "index_automation_messages_on_master_file_id"
  add_index "automation_messages", ["message_type"], :name => "index_automation_messages_on_message_type"
  add_index "automation_messages", ["order_id"], :name => "index_automation_messages_on_order_id"
  add_index "automation_messages", ["processor"], :name => "index_automation_messages_on_processor"
  add_index "automation_messages", ["unit_id"], :name => "index_automation_messages_on_unit_id"
  add_index "automation_messages", ["workflow_type"], :name => "index_automation_messages_on_workflow_type"

  create_table "availability_policies", :force => true do |t|
    t.integer  "bibls_count",        :default => 0
    t.integer  "components_count",   :default => 0
    t.datetime "created_at",                        :null => false
    t.integer  "master_files_count", :default => 0
    t.string   "name"
    t.integer  "units_count",        :default => 0
    t.datetime "updated_at",                        :null => false
    t.string   "xacml_policy_url"
  end

  create_table "bibls", :force => true do |t|
    t.integer  "automation_messages_count",                       :default => 0
    t.integer  "availability_policy_id"
    t.string   "barcode"
    t.string   "call_number"
    t.string   "catalog_key"
    t.text     "citation"
    t.integer  "copy"
    t.datetime "created_at"
    t.string   "creator_name"
    t.string   "creator_name_type"
    t.datetime "date_external_update"
    t.datetime "date_ingested_into_dl"
    t.text     "dc"
    t.text     "desc_metadata"
    t.string   "description"
    t.boolean  "discoverability",                                 :default => true
    t.string   "exemplar"
    t.string   "genre"
    t.integer  "indexing_scenario_id"
    t.boolean  "is_approved",                                     :default => false, :null => false
    t.boolean  "is_collection",                                   :default => false, :null => false
    t.boolean  "is_in_catalog",                                   :default => false, :null => false
    t.boolean  "is_manuscript",                                   :default => false, :null => false
    t.boolean  "is_personal_item",                                :default => false, :null => false
    t.string   "issue"
    t.string   "location"
    t.integer  "master_files_count",                              :default => 0
    t.integer  "orders_count",                                    :default => 0
    t.integer  "parent_bibl_id",                                  :default => 0,     :null => false
    t.string   "pid"
    t.text     "rels_ext"
    t.text     "rels_int"
    t.string   "resource_type"
    t.string   "series_title"
    t.text     "solr",                      :limit => 2147483647
    t.string   "title"
    t.string   "title_control"
    t.integer  "units_count",                                     :default => 0
    t.datetime "updated_at"
    t.integer  "use_right_id"
    t.string   "volume"
    t.string   "year"
    t.string   "year_type"
  end

  add_index "bibls", ["availability_policy_id"], :name => "index_bibls_on_availability_policy_id"
  add_index "bibls", ["barcode"], :name => "index_bibls_on_barcode"
  add_index "bibls", ["call_number"], :name => "index_bibls_on_call_number"
  add_index "bibls", ["catalog_key"], :name => "index_bibls_on_catalog_key"
  add_index "bibls", ["indexing_scenario_id"], :name => "index_bibls_on_indexing_scenario_id"
  add_index "bibls", ["parent_bibl_id"], :name => "index_bibls_on_parent_bibl_id"
  add_index "bibls", ["pid"], :name => "index_bibls_on_pid"
  add_index "bibls", ["title"], :name => "index_bibls_on_title"
  add_index "bibls", ["use_right_id"], :name => "index_bibls_on_use_right_id"

  create_table "bibls_components", :force => true do |t|
    t.integer "bibl_id"
    t.integer "component_id"
  end

  add_index "bibls_components", ["bibl_id"], :name => "index_bibls_components_on_bibl_id"
  add_index "bibls_components", ["component_id"], :name => "index_bibls_components_on_component_id"

  create_table "bibls_legacy_identifiers", :id => false, :force => true do |t|
    t.integer "bibl_id"
    t.integer "legacy_identifier_id"
  end

  add_index "bibls_legacy_identifiers", ["bibl_id"], :name => "index_bibls_legacy_identifiers_on_bibl_id"
  add_index "bibls_legacy_identifiers", ["legacy_identifier_id"], :name => "index_bibls_legacy_identifiers_on_legacy_identifier_id"

  create_table "billing_addresses", :force => true do |t|
    t.string   "address_1"
    t.string   "address_2"
    t.integer  "agency_id"
    t.string   "city"
    t.string   "country"
    t.datetime "created_at"
    t.integer  "customer_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "organization"
    t.string   "phone"
    t.string   "post_code"
    t.string   "state"
    t.datetime "updated_at"
  end

  add_index "billing_addresses", ["agency_id"], :name => "index_billing_addresses_on_agency_id", :unique => true
  add_index "billing_addresses", ["customer_id"], :name => "index_billing_addresses_on_customer_id", :unique => true

  create_table "checkins", :force => true do |t|
    t.datetime "created_at"
    t.integer  "staff_member_id"
    t.integer  "unit_id",         :default => 0, :null => false
    t.datetime "updated_at"
  end

  add_index "checkins", ["staff_member_id"], :name => "staff_member_id"
  add_index "checkins", ["unit_id"], :name => "unit_id"

  create_table "component_types", :force => true do |t|
    t.datetime "created_at"
    t.string   "description"
    t.string   "name"
    t.datetime "updated_at"
  end

  add_index "component_types", ["name"], :name => "index_component_types_on_name", :unique => true

  create_table "components", :force => true do |t|
    t.integer  "availability_policy_id"
    t.integer  "component_type_id",                            :default => 0,    :null => false
    t.text     "content_desc"
    t.datetime "created_at"
    t.string   "date"
    t.datetime "date_ingested_into_dl"
    t.text     "dc"
    t.text     "desc_metadata"
    t.boolean  "discoverability",                              :default => true
    t.string   "exemplar"
    t.integer  "indexing_scenario_id"
    t.integer  "master_files_count",                           :default => 0,    :null => false
    t.integer  "parent_component_id",                          :default => 0,    :null => false
    t.string   "pid"
    t.text     "rels_ext"
    t.text     "rels_int"
    t.text     "solr",                   :limit => 2147483647
    t.string   "title"
    t.datetime "updated_at"
    t.integer  "use_right_id"
  end

  add_index "components", ["availability_policy_id"], :name => "index_components_on_availability_policy_id"
  add_index "components", ["component_type_id"], :name => "index_components_on_component_type_id"
  add_index "components", ["indexing_scenario_id"], :name => "index_components_on_indexing_scenario_id"
  add_index "components", ["use_right_id"], :name => "index_components_on_use_right_id"

  create_table "components_containers", :force => true do |t|
    t.integer "component_id"
    t.integer "container_id"
  end

  add_index "components_containers", ["component_id"], :name => "index_components_containers_on_component_id"
  add_index "components_containers", ["container_id"], :name => "index_components_containers_on_container_id"

  create_table "components_legacy_identifiers", :force => true do |t|
    t.integer "component_id"
    t.integer "legacy_identifier_id"
  end

  add_index "components_legacy_identifiers", ["component_id"], :name => "index_components_legacy_identifiers_on_component_id"
  add_index "components_legacy_identifiers", ["legacy_identifier_id"], :name => "index_components_legacy_identifiers_on_legacy_identifier_id"

  create_table "container_types", :force => true do |t|
    t.string "description"
    t.string "name"
  end

  add_index "container_types", ["name"], :name => "index_container_types_on_name", :unique => true

  create_table "containers", :force => true do |t|
    t.string  "barcode"
    t.integer "container_type_id"
    t.string  "label"
    t.integer "parent_container_id", :default => 0, :null => false
    t.string  "sequence_no"
  end

  add_index "containers", ["container_type_id"], :name => "containers_container_type_id_fk"
  add_index "containers", ["parent_container_id"], :name => "index_containers_on_parent_container_id"

  create_table "customers", :force => true do |t|
    t.integer  "academic_status_id",     :default => 0, :null => false
    t.string   "address_1"
    t.string   "address_2"
    t.string   "city"
    t.string   "country"
    t.datetime "created_at"
    t.integer  "department_id"
    t.string   "email"
    t.string   "first_name"
    t.integer  "heard_about_service_id"
    t.string   "last_name"
    t.integer  "master_files_count",     :default => 0
    t.integer  "orders_count",           :default => 0
    t.string   "organization"
    t.string   "phone"
    t.string   "post_code"
    t.string   "state"
    t.datetime "updated_at"
  end

  add_index "customers", ["academic_status_id"], :name => "index_customers_on_academic_status_id"
  add_index "customers", ["department_id"], :name => "index_customers_on_department_id"
  add_index "customers", ["email"], :name => "index_customers_on_email"
  add_index "customers", ["first_name"], :name => "index_customers_on_first_name"
  add_index "customers", ["heard_about_service_id"], :name => "index_customers_on_heard_about_service_id"
  add_index "customers", ["last_name"], :name => "index_customers_on_last_name"

  create_table "delivery_methods", :force => true do |t|
    t.datetime "created_at"
    t.string   "description"
    t.boolean  "is_internal_use_only", :default => false, :null => false
    t.string   "label"
    t.datetime "updated_at"
  end

  add_index "delivery_methods", ["label"], :name => "index_delivery_methods_on_label", :unique => true

  create_table "delivery_methods_orders", :id => false, :force => true do |t|
    t.integer "delivery_method_id"
    t.integer "order_id"
  end

  add_index "delivery_methods_orders", ["delivery_method_id"], :name => "index_delivery_methods_orders_on_delivery_method_id"
  add_index "delivery_methods_orders", ["order_id"], :name => "index_delivery_methods_orders_on_order_id"

  create_table "departments", :force => true do |t|
    t.datetime "created_at"
    t.integer  "customers_count", :default => 0
    t.string   "name"
    t.datetime "updated_at"
  end

  add_index "departments", ["name"], :name => "index_departments_on_name", :unique => true

  create_table "dvd_delivery_locations", :force => true do |t|
    t.datetime "created_at"
    t.text     "email_desc"
    t.string   "name"
    t.datetime "updated_at"
  end

  add_index "dvd_delivery_locations", ["name"], :name => "index_dvd_delivery_locations_on_name", :unique => true

  create_table "heard_about_resources", :force => true do |t|
    t.datetime "created_at"
    t.string   "description"
    t.boolean  "is_approved",          :default => false, :null => false
    t.boolean  "is_internal_use_only", :default => false, :null => false
    t.datetime "updated_at"
  end

  add_index "heard_about_resources", ["description"], :name => "index_heard_about_resources_on_description"

  create_table "heard_about_services", :force => true do |t|
    t.datetime "created_at"
    t.integer  "customers_count",      :default => 0
    t.string   "description"
    t.boolean  "is_approved",          :default => false, :null => false
    t.boolean  "is_internal_use_only", :default => false, :null => false
    t.datetime "updated_at"
  end

  add_index "heard_about_services", ["description"], :name => "index_heard_about_services_on_description"

  create_table "image_tech_meta", :force => true do |t|
    t.string   "aperture"
    t.datetime "capture_date"
    t.string   "color_profile"
    t.string   "color_space"
    t.string   "compression"
    t.datetime "created_at"
    t.integer  "depth"
    t.string   "equipment"
    t.string   "exif_version"
    t.string   "exposure_bias"
    t.string   "exposure_time"
    t.decimal  "focal_length",   :precision => 10, :scale => 0
    t.integer  "height"
    t.string   "image_format"
    t.integer  "iso"
    t.integer  "master_file_id",                                :default => 0, :null => false
    t.string   "model"
    t.integer  "resolution"
    t.string   "software"
    t.datetime "updated_at"
    t.integer  "width"
  end

  add_index "image_tech_meta", ["master_file_id"], :name => "index_image_tech_meta_on_master_file_id"

  create_table "indexing_scenarios", :force => true do |t|
    t.integer  "bibls_count",        :default => 0
    t.integer  "components_count",   :default => 0
    t.datetime "created_at"
    t.string   "datastream_name"
    t.integer  "master_files_count", :default => 0
    t.string   "name"
    t.string   "pid"
    t.string   "repository_url"
    t.integer  "units_count",        :default => 0
    t.datetime "updated_at"
  end

  create_table "intended_uses", :force => true do |t|
    t.datetime "created_at"
    t.string   "description"
    t.boolean  "is_approved",          :default => false, :null => false
    t.boolean  "is_internal_use_only", :default => false, :null => false
    t.integer  "units_count",          :default => 0
    t.datetime "updated_at"
  end

  add_index "intended_uses", ["description"], :name => "index_intended_uses_on_description", :unique => true

  create_table "invoices", :force => true do |t|
    t.datetime "created_at"
    t.datetime "date_fee_paid"
    t.datetime "date_invoice"
    t.datetime "date_second_notice_sent"
    t.integer  "fee_amount_paid"
    t.text     "invoice_content"
    t.binary   "invoice_copy",            :limit => 16777215
    t.integer  "invoice_number"
    t.text     "notes"
    t.integer  "order_id",                                    :default => 0, :null => false
    t.text     "transmittal_number"
    t.datetime "updated_at"
  end

  add_index "invoices", ["order_id"], :name => "index_invoices_on_order_id"

  create_table "legacy_identifiers", :force => true do |t|
    t.datetime "created_at"
    t.string   "description"
    t.string   "label"
    t.string   "legacy_identifier"
    t.datetime "updated_at"
  end

  add_index "legacy_identifiers", ["label"], :name => "index_legacy_identifiers_on_label"
  add_index "legacy_identifiers", ["legacy_identifier"], :name => "index_legacy_identifiers_on_legacy_identifier"

  create_table "legacy_identifiers_master_files", :id => false, :force => true do |t|
    t.integer "legacy_identifier_id"
    t.integer "master_file_id"
  end

  add_index "legacy_identifiers_master_files", ["legacy_identifier_id"], :name => "index_legacy_identifiers_master_files_on_legacy_identifier_id"
  add_index "legacy_identifiers_master_files", ["master_file_id"], :name => "index_legacy_identifiers_master_files_on_master_file_id"

  create_table "master_files", :force => true do |t|
    t.integer  "automation_messages_count",                       :default => 0
    t.integer  "availability_policy_id"
    t.integer  "component_id"
    t.datetime "created_at"
    t.datetime "date_archived"
    t.datetime "date_ingested_into_dl"
    t.text     "dc"
    t.text     "desc_metadata"
    t.string   "description"
    t.boolean  "discoverability",                                 :default => false
    t.string   "filename"
    t.integer  "filesize"
    t.integer  "indexing_scenario_id"
    t.string   "md5"
    t.string   "pid"
    t.text     "rels_ext"
    t.text     "rels_int"
    t.text     "solr",                      :limit => 2147483647
    t.string   "tech_meta_type"
    t.string   "title"
    t.text     "transcription_text"
    t.integer  "unit_id",                                         :default => 0,     :null => false
    t.datetime "updated_at"
    t.integer  "use_right_id"
  end

  add_index "master_files", ["availability_policy_id"], :name => "index_master_files_on_availability_policy_id"
  add_index "master_files", ["component_id"], :name => "index_master_files_on_component_id"
  add_index "master_files", ["filename"], :name => "index_master_files_on_filename"
  add_index "master_files", ["indexing_scenario_id"], :name => "index_master_files_on_indexing_scenario_id"
  add_index "master_files", ["pid"], :name => "index_master_files_on_pid"
  add_index "master_files", ["tech_meta_type"], :name => "index_master_files_on_tech_meta_type"
  add_index "master_files", ["title"], :name => "index_master_files_on_title"
  add_index "master_files", ["unit_id"], :name => "index_master_files_on_unit_id"
  add_index "master_files", ["use_right_id"], :name => "index_master_files_on_use_right_id"

  create_table "orders", :force => true do |t|
    t.integer  "agency_id"
    t.integer  "automation_messages_count",                                        :default => 0
    t.datetime "created_at"
    t.integer  "customer_id",                                                      :default => 0,     :null => false
    t.datetime "date_archiving_complete"
    t.datetime "date_canceled"
    t.datetime "date_customer_notified"
    t.datetime "date_deferred"
    t.date     "date_due"
    t.datetime "date_fee_estimate_sent_to_customer"
    t.datetime "date_finalization_begun"
    t.datetime "date_order_approved"
    t.datetime "date_patron_deliverables_complete"
    t.datetime "date_permissions_given"
    t.datetime "date_request_submitted"
    t.datetime "date_started"
    t.integer  "dvd_delivery_location_id"
    t.text     "email"
    t.string   "entered_by"
    t.decimal  "fee_actual",                         :precision => 7, :scale => 2
    t.decimal  "fee_estimated",                      :precision => 7, :scale => 2
    t.integer  "invoices_count",                                                   :default => 0
    t.boolean  "is_approved",                                                      :default => false, :null => false
    t.integer  "master_files_count",                                               :default => 0
    t.string   "order_status"
    t.string   "order_title"
    t.text     "special_instructions"
    t.text     "staff_notes"
    t.integer  "units_count",                                                      :default => 0
    t.datetime "updated_at"
  end

  add_index "orders", ["agency_id"], :name => "index_orders_on_agency_id"
  add_index "orders", ["customer_id"], :name => "index_orders_on_customer_id"
  add_index "orders", ["date_archiving_complete"], :name => "index_orders_on_date_archiving_complete"
  add_index "orders", ["date_due"], :name => "index_orders_on_date_due"
  add_index "orders", ["date_order_approved"], :name => "index_orders_on_date_order_approved"
  add_index "orders", ["date_request_submitted"], :name => "index_orders_on_date_request_submitted"
  add_index "orders", ["dvd_delivery_location_id"], :name => "index_orders_on_dvd_delivery_location_id"
  add_index "orders", ["order_status"], :name => "index_orders_on_order_status"

  create_table "sessions", :force => true do |t|
    t.datetime "created_at"
    t.text     "data"
    t.string   "session_id", :null => false
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "sql_reports", :force => true do |t|
    t.datetime "created_at"
    t.string   "description"
    t.string   "name"
    t.text     "sql"
    t.datetime "updated_at"
  end

  create_table "unit_import_sources", :force => true do |t|
    t.datetime "created_at"
    t.text     "source",     :limit => 2147483647
    t.string   "standard"
    t.integer  "unit_id",                          :default => 0, :null => false
    t.datetime "updated_at"
    t.string   "version"
  end

  add_index "unit_import_sources", ["unit_id"], :name => "index_unit_import_sources_on_unit_id"

  create_table "units", :force => true do |t|
    t.integer  "archive_id"
    t.integer  "automation_messages_count",      :default => 0
    t.integer  "availability_policy_id"
    t.integer  "bibl_id"
    t.boolean  "checked_out",                    :default => false
    t.datetime "created_at"
    t.datetime "date_archived"
    t.datetime "date_dl_deliverables_ready"
    t.datetime "date_materials_received"
    t.datetime "date_materials_returned"
    t.datetime "date_patron_deliverables_ready"
    t.datetime "date_queued_for_ingest"
    t.string   "deliverable_format"
    t.string   "deliverable_resolution"
    t.string   "deliverable_resolution_unit"
    t.boolean  "exclude_from_dl",                :default => false, :null => false
    t.integer  "heard_about_resource_id"
    t.boolean  "include_in_dl",                  :default => false
    t.integer  "indexing_scenario_id"
    t.integer  "intended_use_id"
    t.boolean  "master_file_discoverability",    :default => false
    t.integer  "master_files_count",             :default => 0
    t.integer  "order_id",                       :default => 0,     :null => false
    t.text     "patron_source_url"
    t.boolean  "remove_watermark",               :default => false
    t.text     "special_instructions"
    t.text     "staff_notes"
    t.integer  "unit_extent_actual"
    t.integer  "unit_extent_estimated"
    t.string   "unit_status"
    t.datetime "updated_at"
    t.integer  "use_right_id"
  end

  add_index "units", ["archive_id"], :name => "index_units_on_archive_id"
  add_index "units", ["availability_policy_id"], :name => "index_units_on_availability_policy_id"
  add_index "units", ["bibl_id"], :name => "index_units_on_bibl_id"
  add_index "units", ["date_archived"], :name => "index_units_on_date_archived"
  add_index "units", ["date_dl_deliverables_ready"], :name => "index_units_on_date_dl_deliverables_ready"
  add_index "units", ["heard_about_resource_id"], :name => "index_units_on_heard_about_resource_id"
  add_index "units", ["indexing_scenario_id"], :name => "index_units_on_indexing_scenario_id"
  add_index "units", ["intended_use_id"], :name => "index_units_on_intended_use_id"
  add_index "units", ["order_id"], :name => "index_units_on_order_id"
  add_index "units", ["use_right_id"], :name => "index_units_on_use_right_id"

  create_table "use_rights", :force => true do |t|
    t.integer  "bibls_count",        :default => 0
    t.integer  "components_count",   :default => 0
    t.datetime "created_at"
    t.string   "description"
    t.integer  "master_files_count", :default => 0
    t.string   "name"
    t.integer  "units_count",        :default => 0
    t.datetime "updated_at"
  end

  add_index "use_rights", ["name"], :name => "index_use_rights_on_name", :unique => true

  add_foreign_key "automation_messages", "bibls", :name => "automation_messages_bibl_id_fk"
  add_foreign_key "automation_messages", "components", :name => "automation_messages_component_id_fk"
  add_foreign_key "automation_messages", "master_files", :name => "automation_messages_master_file_id_fk"
  add_foreign_key "automation_messages", "orders", :name => "automation_messages_order_id_fk"
  add_foreign_key "automation_messages", "units", :name => "automation_messages_unit_id_fk"

  add_foreign_key "bibls", "availability_policies", :name => "bibls_availability_policy_id_fk"
  add_foreign_key "bibls", "indexing_scenarios", :name => "bibls_indexing_scenario_id_fk"
  add_foreign_key "bibls", "use_rights", :name => "bibls_use_right_id_fk"

  add_foreign_key "bibls_components", "bibls", :name => "bibls_components_bibl_id_fk"
  add_foreign_key "bibls_components", "components", :name => "bibls_components_component_id_fk"

  add_foreign_key "bibls_legacy_identifiers", "bibls", :name => "bibls_legacy_identifiers_bibl_id_fk"
  add_foreign_key "bibls_legacy_identifiers", "legacy_identifiers", :name => "bibls_legacy_identifiers_legacy_identifier_id_fk"

  add_foreign_key "billing_addresses", "agencies", :name => "billing_addresses_agency_id_fk"
  add_foreign_key "billing_addresses", "customers", :name => "billing_addresses_customer_id_fk"

  add_foreign_key "components", "availability_policies", :name => "components_availability_policy_id_fk"
  add_foreign_key "components", "component_types", :name => "components_component_type_id_fk"
  add_foreign_key "components", "indexing_scenarios", :name => "components_indexing_scenario_id_fk"
  add_foreign_key "components", "use_rights", :name => "components_use_right_id_fk"

  add_foreign_key "components_containers", "components", :name => "components_containers_component_id_fk"
  add_foreign_key "components_containers", "containers", :name => "components_containers_container_id_fk"

  add_foreign_key "containers", "container_types", :name => "containers_container_type_id_fk"

  add_foreign_key "customers", "academic_statuses", :name => "customers_academic_status_id_fk"
  add_foreign_key "customers", "departments", :name => "customers_department_id_fk"
  add_foreign_key "customers", "heard_about_services", :name => "customers_heard_about_service_id_fk"

  add_foreign_key "delivery_methods_orders", "delivery_methods", :name => "delivery_methods_orders_delivery_method_id_fk"
  add_foreign_key "delivery_methods_orders", "orders", :name => "delivery_methods_orders_order_id_fk"

  add_foreign_key "image_tech_meta", "master_files", :name => "image_tech_meta_master_file_id_fk"

  add_foreign_key "invoices", "orders", :name => "invoices_order_id_fk"

  add_foreign_key "legacy_identifiers_master_files", "legacy_identifiers", :name => "legacy_identifiers_master_files_legacy_identifier_id_fk"
  add_foreign_key "legacy_identifiers_master_files", "master_files", :name => "legacy_identifiers_master_files_master_file_id_fk"

  add_foreign_key "master_files", "availability_policies", :name => "master_files_availability_policy_id_fk"
  add_foreign_key "master_files", "components", :name => "master_files_component_id_fk"
  add_foreign_key "master_files", "indexing_scenarios", :name => "master_files_indexing_scenario_id_fk"
  add_foreign_key "master_files", "units", :name => "master_files_unit_id_fk"
  add_foreign_key "master_files", "use_rights", :name => "master_files_use_right_id_fk"

  add_foreign_key "orders", "agencies", :name => "orders_agency_id_fk"
  add_foreign_key "orders", "customers", :name => "orders_customer_id_fk"
  add_foreign_key "orders", "dvd_delivery_locations", :name => "orders_dvd_delivery_location_id_fk"

  add_foreign_key "unit_import_sources", "units", :name => "unit_import_sources_unit_id_fk"

  add_foreign_key "units", "archives", :name => "units_archive_id_fk"
  add_foreign_key "units", "availability_policies", :name => "units_availability_policy_id_fk"
  add_foreign_key "units", "bibls", :name => "units_bibl_id_fk"
  add_foreign_key "units", "heard_about_resources", :name => "units_heard_about_resource_id_fk"
  add_foreign_key "units", "indexing_scenarios", :name => "units_indexing_scenario_id_fk"
  add_foreign_key "units", "intended_uses", :name => "units_intended_use_id_fk"
  add_foreign_key "units", "orders", :name => "units_order_id_fk"
  add_foreign_key "units", "use_rights", :name => "units_use_right_id_fk"

end
