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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160427200829) do

  create_table "academic_statuses", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customers_count", default: 0
  end

  add_index "academic_statuses", ["name"], name: "index_academic_statuses_on_name", unique: true, using: :btree

  create_table "active_admin_comments", force: true do |t|
    t.integer  "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_admin_notes_on_resource_type_and_resource_id", using: :btree

  create_table "addresses", force: true do |t|
    t.integer  "addressable_id",              null: false
    t.string   "addressable_type", limit: 20, null: false
    t.string   "address_type",     limit: 20, null: false
    t.string   "last_name"
    t.string   "first_name"
    t.string   "address_1"
    t.string   "address_2"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "post_code"
    t.string   "phone"
    t.string   "organization"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "agencies", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ancestry"
    t.string   "names_depth_cache"
    t.integer  "orders_count",      default: 0
  end

  add_index "agencies", ["ancestry"], name: "index_agencies_on_ancestry", using: :btree
  add_index "agencies", ["name"], name: "index_agencies_on_name", unique: true, using: :btree

  create_table "availability_policies", force: true do |t|
    t.string   "name"
    t.integer  "bibls_count",        default: 0
    t.integer  "components_count",   default: 0
    t.integer  "master_files_count", default: 0
    t.integer  "units_count",        default: 0
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "repository_url"
    t.string   "pid"
  end

  create_table "bibls", force: true do |t|
    t.boolean  "is_approved",                               default: false, null: false
    t.boolean  "is_personal_item",                          default: false, null: false
    t.string   "resource_type"
    t.string   "genre"
    t.boolean  "is_manuscript",                             default: false, null: false
    t.boolean  "is_collection",                             default: false, null: false
    t.text     "title"
    t.string   "description"
    t.string   "series_title"
    t.string   "creator_name"
    t.string   "creator_name_type"
    t.string   "catalog_key"
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
    t.boolean  "is_in_catalog",                             default: false, null: false
    t.string   "issue"
    t.text     "citation"
    t.string   "exemplar"
    t.integer  "parent_bibl_id",                            default: 0,     null: false
    t.text     "desc_metadata"
    t.text     "rels_ext"
    t.text     "solr",                   limit: 2147483647
    t.text     "dc"
    t.text     "rels_int"
    t.boolean  "discoverability",                           default: true
    t.integer  "indexing_scenario_id"
    t.datetime "date_dl_ingest"
    t.datetime "date_dl_update"
    t.integer  "units_count",                               default: 0
    t.integer  "availability_policy_id"
    t.integer  "use_right_id"
    t.boolean  "dpla",                                      default: false
    t.string   "cataloging_source"
    t.string   "collection_facet"
    t.integer  "index_destination_id"
  end

  add_index "bibls", ["availability_policy_id"], name: "index_bibls_on_availability_policy_id", using: :btree
  add_index "bibls", ["barcode"], name: "index_bibls_on_barcode", using: :btree
  add_index "bibls", ["call_number"], name: "index_bibls_on_call_number", using: :btree
  add_index "bibls", ["catalog_key"], name: "index_bibls_on_catalog_key", using: :btree
  add_index "bibls", ["cataloging_source"], name: "index_bibls_on_cataloging_source", using: :btree
  add_index "bibls", ["dpla"], name: "index_bibls_on_dpla", using: :btree
  add_index "bibls", ["indexing_scenario_id"], name: "index_bibls_on_indexing_scenario_id", using: :btree
  add_index "bibls", ["parent_bibl_id"], name: "index_bibls_on_parent_bibl_id", using: :btree
  add_index "bibls", ["pid"], name: "index_bibls_on_pid", using: :btree
  add_index "bibls", ["use_right_id"], name: "index_bibls_on_use_right_id", using: :btree

  create_table "bibls_components", id: false, force: true do |t|
    t.integer "bibl_id"
    t.integer "component_id"
  end

  add_index "bibls_components", ["bibl_id"], name: "bibl_id", using: :btree
  add_index "bibls_components", ["component_id"], name: "component_id", using: :btree

  create_table "bibls_legacy_identifiers", id: false, force: true do |t|
    t.integer "legacy_identifier_id"
    t.integer "bibl_id"
  end

  add_index "bibls_legacy_identifiers", ["bibl_id"], name: "index_bibls_legacy_identifiers_on_bibl_id", using: :btree
  add_index "bibls_legacy_identifiers", ["legacy_identifier_id"], name: "index_bibls_legacy_identifiers_on_legacy_identifier_id", using: :btree

  create_table "component_types", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "components_count"
  end

  add_index "component_types", ["name"], name: "index_component_types_on_name", unique: true, using: :btree

  create_table "components", force: true do |t|
    t.integer  "component_type_id",                          default: 0,    null: false
    t.integer  "parent_component_id",                        default: 0,    null: false
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
    t.text     "solr",                    limit: 2147483647
    t.text     "dc"
    t.text     "rels_int"
    t.boolean  "discoverability",                            default: true
    t.integer  "indexing_scenario_id"
    t.text     "level"
    t.string   "ead_id_att"
    t.integer  "parent_ead_ref_id"
    t.integer  "ead_ref_id"
    t.integer  "availability_policy_id"
    t.datetime "date_dl_ingest"
    t.datetime "date_dl_update"
    t.integer  "use_right_id"
    t.integer  "master_files_count",                         default: 0,    null: false
    t.string   "exemplar"
    t.string   "ancestry"
    t.string   "pids_depth_cache"
    t.string   "ead_id_atts_depth_cache"
    t.integer  "followed_by_id"
    t.text     "legacy_ead"
    t.text     "physical_desc"
    t.text     "scope_content"
    t.integer  "index_destination_id"
  end

  add_index "components", ["ancestry"], name: "index_components_on_ancestry", using: :btree
  add_index "components", ["availability_policy_id"], name: "index_components_on_availability_policy_id", using: :btree
  add_index "components", ["component_type_id"], name: "index_components_on_component_type_id", using: :btree
  add_index "components", ["ead_ref_id"], name: "ead_ref_id", using: :btree
  add_index "components", ["followed_by_id"], name: "index_components_on_followed_by_id", using: :btree
  add_index "components", ["indexing_scenario_id"], name: "index_components_on_indexing_scenario_id", using: :btree
  add_index "components", ["use_right_id"], name: "index_components_on_use_right_id", using: :btree

  create_table "components_containers", id: false, force: true do |t|
    t.integer "container_id"
    t.integer "component_id"
  end

  add_index "components_containers", ["component_id"], name: "component_id", using: :btree
  add_index "components_containers", ["container_id"], name: "container_id", using: :btree

  create_table "components_legacy_identifiers", id: false, force: true do |t|
    t.integer "component_id"
    t.integer "legacy_identifier_id"
  end

  add_index "components_legacy_identifiers", ["component_id"], name: "component_id", using: :btree
  add_index "components_legacy_identifiers", ["legacy_identifier_id"], name: "legacy_identifier_id", using: :btree

  create_table "container_types", force: true do |t|
    t.string "name"
    t.string "description"
  end

  add_index "container_types", ["name"], name: "index_container_types_on_name", unique: true, using: :btree

  create_table "containers", force: true do |t|
    t.string   "barcode"
    t.string   "container_type"
    t.string   "label"
    t.string   "sequence_no"
    t.integer  "parent_container_id", default: 0, null: false
    t.integer  "legacy_component_id", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "container_type_id"
  end

  add_index "containers", ["container_type_id"], name: "containers_container_type_id_fk", using: :btree

  create_table "customers", force: true do |t|
    t.integer  "department_id"
    t.integer  "academic_status_id",     default: 0, null: false
    t.integer  "heard_about_service_id"
    t.string   "last_name"
    t.string   "first_name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "master_files_count",     default: 0
    t.integer  "orders_count",           default: 0
  end

  add_index "customers", ["academic_status_id"], name: "index_customers_on_academic_status_id", using: :btree
  add_index "customers", ["department_id"], name: "index_customers_on_department_id", using: :btree
  add_index "customers", ["email"], name: "index_customers_on_email", using: :btree
  add_index "customers", ["first_name"], name: "index_customers_on_first_name", using: :btree
  add_index "customers", ["heard_about_service_id"], name: "index_customers_on_heard_about_service_id", using: :btree
  add_index "customers", ["last_name"], name: "index_customers_on_last_name", using: :btree

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "departments", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customers_count", default: 0
  end

  add_index "departments", ["name"], name: "index_departments_on_name", unique: true, using: :btree

  create_table "heard_about_resources", force: true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_approved",          default: false, null: false
    t.boolean  "is_internal_use_only", default: false, null: false
    t.integer  "units_count"
  end

  add_index "heard_about_resources", ["description"], name: "index_heard_about_resources_on_description", using: :btree

  create_table "heard_about_services", force: true do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_approved",          default: false, null: false
    t.boolean  "is_internal_use_only", default: false, null: false
    t.integer  "customers_count",      default: 0
  end

  add_index "heard_about_services", ["description"], name: "index_heard_about_services_on_description", using: :btree

  create_table "image_tech_meta", force: true do |t|
    t.integer  "master_file_id",                          default: 0, null: false
    t.string   "image_format"
    t.integer  "width"
    t.integer  "height"
    t.integer  "resolution"
    t.string   "color_space"
    t.integer  "depth"
    t.string   "compression"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "color_profile"
    t.string   "equipment"
    t.string   "software"
    t.string   "model"
    t.string   "exif_version"
    t.datetime "capture_date"
    t.integer  "iso"
    t.string   "exposure_bias"
    t.string   "exposure_time"
    t.string   "aperture"
    t.decimal  "focal_length",   precision: 10, scale: 0
  end

  add_index "image_tech_meta", ["master_file_id"], name: "index_image_tech_meta_on_master_file_id", using: :btree

  create_table "index_destinations", force: true do |t|
    t.string   "nickname"
    t.string   "hostname",         default: "localhost"
    t.string   "port",             default: "8080"
    t.string   "protocol",         default: "http"
    t.string   "context",          default: "solr"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "bibls_count"
    t.integer  "units_count"
    t.integer  "components_count"
  end

  create_table "indexing_scenarios", force: true do |t|
    t.string   "name"
    t.string   "pid"
    t.string   "datastream_name"
    t.string   "repository_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bibls_count",        default: 0
    t.integer  "components_count",   default: 0
    t.integer  "master_files_count", default: 0
    t.integer  "units_count",        default: 0
  end

  create_table "intended_uses", force: true do |t|
    t.string   "description"
    t.boolean  "is_internal_use_only",        default: false, null: false
    t.boolean  "is_approved",                 default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "units_count",                 default: 0
    t.string   "deliverable_format"
    t.string   "deliverable_resolution"
    t.string   "deliverable_resolution_unit"
  end

  add_index "intended_uses", ["description"], name: "index_intended_uses_on_description", unique: true, using: :btree

  create_table "invoices", force: true do |t|
    t.integer  "order_id",                                 default: 0,     null: false
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
    t.binary   "invoice_copy",            limit: 16777215
    t.boolean  "permanent_nonpayment",                     default: false
  end

  add_index "invoices", ["order_id"], name: "index_invoices_on_order_id", using: :btree

  create_table "job_statuses", force: true do |t|
    t.string   "name",                                null: false
    t.string   "status",          default: "pending", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer  "failures",        default: 0,         null: false
    t.string   "error"
    t.integer  "originator_id"
    t.string   "originator_type"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "params"
  end

  create_table "legacy_identifiers", force: true do |t|
    t.string   "label"
    t.string   "description"
    t.string   "legacy_identifier"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "legacy_identifiers", ["label"], name: "index_legacy_identifiers_on_label", using: :btree
  add_index "legacy_identifiers", ["legacy_identifier"], name: "index_legacy_identifiers_on_legacy_identifier", using: :btree

  create_table "legacy_identifiers_master_files", id: false, force: true do |t|
    t.integer "legacy_identifier_id"
    t.integer "master_file_id"
  end

  add_index "legacy_identifiers_master_files", ["legacy_identifier_id"], name: "index_legacy_identifiers_master_files_on_legacy_identifier_id", using: :btree
  add_index "legacy_identifiers_master_files", ["master_file_id"], name: "index_legacy_identifiers_master_files_on_master_file_id", using: :btree

  create_table "legacy_identifiers_units", id: false, force: true do |t|
    t.integer "legacy_identifier_id"
    t.integer "unit_id"
  end

  add_index "legacy_identifiers_units", ["unit_id", "legacy_identifier_id"], name: "units_legacy_ids_index", using: :btree

  create_table "master_files", force: true do |t|
    t.integer  "unit_id",                                   default: 0,     null: false
    t.integer  "component_id"
    t.string   "tech_meta_type"
    t.string   "filename"
    t.integer  "filesize"
    t.string   "title"
    t.datetime "date_archived"
    t.string   "description"
    t.string   "pid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "transcription_text"
    t.text     "desc_metadata"
    t.text     "rels_ext"
    t.text     "solr",                   limit: 2147483647
    t.text     "dc"
    t.text     "rels_int"
    t.boolean  "discoverability",                           default: false
    t.string   "md5"
    t.integer  "indexing_scenario_id"
    t.integer  "availability_policy_id"
    t.integer  "use_right_id"
    t.datetime "date_dl_ingest"
    t.datetime "date_dl_update"
    t.boolean  "dpla",                                      default: false
    t.string   "creator_death_date"
    t.string   "creation_date"
    t.string   "primary_author"
  end

  add_index "master_files", ["availability_policy_id"], name: "index_master_files_on_availability_policy_id", using: :btree
  add_index "master_files", ["component_id"], name: "index_master_files_on_component_id", using: :btree
  add_index "master_files", ["date_dl_ingest"], name: "index_master_files_on_date_dl_ingest", using: :btree
  add_index "master_files", ["date_dl_update"], name: "index_master_files_on_date_dl_update", using: :btree
  add_index "master_files", ["dpla"], name: "index_master_files_on_dpla", using: :btree
  add_index "master_files", ["filename"], name: "index_master_files_on_filename", using: :btree
  add_index "master_files", ["indexing_scenario_id"], name: "index_master_files_on_indexing_scenario_id", using: :btree
  add_index "master_files", ["pid"], name: "index_master_files_on_pid", using: :btree
  add_index "master_files", ["tech_meta_type"], name: "index_master_files_on_tech_meta_type", using: :btree
  add_index "master_files", ["title"], name: "index_master_files_on_title", using: :btree
  add_index "master_files", ["unit_id"], name: "index_master_files_on_unit_id", using: :btree
  add_index "master_files", ["use_right_id"], name: "index_master_files_on_use_right_id", using: :btree

  create_table "orders", force: true do |t|
    t.integer  "customer_id",                                                default: 0,     null: false
    t.integer  "agency_id"
    t.string   "order_status"
    t.boolean  "is_approved",                                                default: false, null: false
    t.string   "order_title"
    t.datetime "date_request_submitted"
    t.datetime "date_order_approved"
    t.datetime "date_deferred"
    t.datetime "date_canceled"
    t.datetime "date_permissions_given"
    t.datetime "date_started"
    t.date     "date_due"
    t.datetime "date_customer_notified"
    t.decimal  "fee_estimated",                      precision: 7, scale: 2
    t.decimal  "fee_actual",                         precision: 7, scale: 2
    t.string   "entered_by"
    t.text     "special_instructions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "staff_notes"
    t.text     "email"
    t.datetime "date_patron_deliverables_complete"
    t.datetime "date_archiving_complete"
    t.datetime "date_finalization_begun"
    t.datetime "date_fee_estimate_sent_to_customer"
    t.integer  "units_count",                                                default: 0
    t.integer  "invoices_count",                                             default: 0
    t.integer  "master_files_count",                                         default: 0
  end

  add_index "orders", ["agency_id"], name: "index_orders_on_agency_id", using: :btree
  add_index "orders", ["customer_id"], name: "index_orders_on_customer_id", using: :btree
  add_index "orders", ["date_archiving_complete"], name: "index_orders_on_date_archiving_complete", using: :btree
  add_index "orders", ["date_due"], name: "index_orders_on_date_due", using: :btree
  add_index "orders", ["date_order_approved"], name: "index_orders_on_date_order_approved", using: :btree
  add_index "orders", ["date_request_submitted"], name: "index_orders_on_date_request_submitted", using: :btree
  add_index "orders", ["order_status"], name: "index_orders_on_order_status", using: :btree

  create_table "roles", force: true do |t|
    t.string "name", null: false
  end

  create_table "sql_reports", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.text     "sql"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "staff_members", force: true do |t|
    t.integer  "access_level_id", default: 0,     null: false
    t.string   "computing_id"
    t.string   "last_name"
    t.string   "first_name"
    t.boolean  "is_active",       default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.integer  "role_id",         default: 1
  end

  add_index "staff_members", ["access_level_id"], name: "access_level_id", using: :btree
  add_index "staff_members", ["computing_id"], name: "index_staff_members_on_computing_id", unique: true, using: :btree

  create_table "units", force: true do |t|
    t.integer  "order_id",                       default: 0,     null: false
    t.integer  "bibl_id"
    t.integer  "heard_about_resource_id"
    t.string   "unit_status"
    t.datetime "date_materials_received"
    t.datetime "date_materials_returned"
    t.integer  "unit_extent_estimated"
    t.integer  "unit_extent_actual"
    t.text     "patron_source_url"
    t.text     "special_instructions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "intended_use_id"
    t.boolean  "exclude_from_dl",                default: false, null: false
    t.text     "staff_notes"
    t.integer  "use_right_id"
    t.datetime "date_queued_for_ingest"
    t.datetime "date_archived"
    t.datetime "date_patron_deliverables_ready"
    t.boolean  "include_in_dl",                  default: false
    t.datetime "date_dl_deliverables_ready"
    t.boolean  "remove_watermark",               default: false
    t.boolean  "master_file_discoverability",    default: false
    t.integer  "indexing_scenario_id"
    t.boolean  "checked_out",                    default: false
    t.integer  "availability_policy_id"
    t.integer  "master_files_count",             default: 0
    t.integer  "index_destination_id"
  end

  add_index "units", ["availability_policy_id"], name: "index_units_on_availability_policy_id", using: :btree
  add_index "units", ["bibl_id"], name: "index_units_on_bibl_id", using: :btree
  add_index "units", ["date_archived"], name: "index_units_on_date_archived", using: :btree
  add_index "units", ["date_dl_deliverables_ready"], name: "index_units_on_date_dl_deliverables_ready", using: :btree
  add_index "units", ["heard_about_resource_id"], name: "index_units_on_heard_about_resource_id", using: :btree
  add_index "units", ["indexing_scenario_id"], name: "index_units_on_indexing_scenario_id", using: :btree
  add_index "units", ["intended_use_id"], name: "index_units_on_intended_use_id", using: :btree
  add_index "units", ["order_id"], name: "index_units_on_order_id", using: :btree
  add_index "units", ["use_right_id"], name: "index_units_on_use_right_id", using: :btree

  create_table "use_rights", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bibls_count",        default: 0
    t.integer  "components_count",   default: 0
    t.integer  "master_files_count", default: 0
    t.integer  "units_count",        default: 0
  end

  add_index "use_rights", ["name"], name: "index_use_rights_on_name", unique: true, using: :btree

end
