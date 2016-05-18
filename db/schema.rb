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

ActiveRecord::Schema.define(version: 20160518152341) do

  create_table "academic_statuses", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customers_count", limit: 4,   default: 0
  end

  add_index "academic_statuses", ["name"], name: "index_academic_statuses_on_name", unique: true, using: :btree

  create_table "active_admin_comments", force: :cascade do |t|
    t.integer  "resource_id",   limit: 4,     null: false
    t.string   "resource_type", limit: 255,   null: false
    t.integer  "author_id",     limit: 4
    t.string   "author_type",   limit: 255
    t.text     "body",          limit: 65535
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "namespace",     limit: 255
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_admin_notes_on_resource_type_and_resource_id", using: :btree

  create_table "addresses", force: :cascade do |t|
    t.integer  "addressable_id",   limit: 4,   null: false
    t.string   "addressable_type", limit: 20,  null: false
    t.string   "address_type",     limit: 20,  null: false
    t.string   "last_name",        limit: 255
    t.string   "first_name",       limit: 255
    t.string   "address_1",        limit: 255
    t.string   "address_2",        limit: 255
    t.string   "city",             limit: 255
    t.string   "state",            limit: 255
    t.string   "country",          limit: 255
    t.string   "post_code",        limit: 255
    t.string   "phone",            limit: 255
    t.string   "organization",     limit: 255
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "agencies", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.string   "description",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ancestry",          limit: 255
    t.string   "names_depth_cache", limit: 255
    t.integer  "orders_count",      limit: 4,   default: 0
  end

  add_index "agencies", ["ancestry"], name: "index_agencies_on_ancestry", using: :btree
  add_index "agencies", ["name"], name: "index_agencies_on_name", unique: true, using: :btree

  create_table "availability_policies", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.integer  "bibls_count",        limit: 4,   default: 0
    t.integer  "components_count",   limit: 4,   default: 0
    t.integer  "master_files_count", limit: 4,   default: 0
    t.integer  "units_count",        limit: 4,   default: 0
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "repository_url",     limit: 255
    t.string   "pid",                limit: 255
  end

  create_table "bibls", force: :cascade do |t|
    t.boolean  "is_approved",                          default: false, null: false
    t.boolean  "is_personal_item",                     default: false, null: false
    t.string   "resource_type",          limit: 255
    t.string   "genre",                  limit: 255
    t.boolean  "is_manuscript",                        default: false, null: false
    t.boolean  "is_collection",                        default: false, null: false
    t.text     "title",                  limit: 65535
    t.string   "description",            limit: 255
    t.string   "series_title",           limit: 255
    t.string   "creator_name",           limit: 255
    t.string   "creator_name_type",      limit: 255
    t.string   "catalog_key",            limit: 255
    t.string   "title_control",          limit: 255
    t.string   "barcode",                limit: 255
    t.string   "call_number",            limit: 255
    t.integer  "copy",                   limit: 4
    t.string   "volume",                 limit: 255
    t.string   "location",               limit: 255
    t.string   "year",                   limit: 255
    t.string   "year_type",              limit: 255
    t.datetime "date_external_update"
    t.string   "pid",                    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_in_catalog",                        default: false, null: false
    t.string   "issue",                  limit: 255
    t.text     "citation",               limit: 65535
    t.string   "exemplar",               limit: 255
    t.integer  "parent_bibl_id",         limit: 4,     default: 0,     null: false
    t.text     "desc_metadata",          limit: 65535
    t.boolean  "discoverability",                      default: true
    t.integer  "indexing_scenario_id",   limit: 4
    t.datetime "date_dl_ingest"
    t.datetime "date_dl_update"
    t.integer  "units_count",            limit: 4,     default: 0
    t.integer  "availability_policy_id", limit: 4
    t.integer  "use_right_id",           limit: 4
    t.boolean  "dpla",                                 default: false
    t.string   "cataloging_source",      limit: 255
    t.string   "collection_facet",       limit: 255
    t.integer  "index_destination_id",   limit: 4
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

  create_table "bibls_components", id: false, force: :cascade do |t|
    t.integer "bibl_id",      limit: 4
    t.integer "component_id", limit: 4
  end

  add_index "bibls_components", ["bibl_id"], name: "bibl_id", using: :btree
  add_index "bibls_components", ["component_id"], name: "component_id", using: :btree

  create_table "bibls_legacy_identifiers", id: false, force: :cascade do |t|
    t.integer "legacy_identifier_id", limit: 4
    t.integer "bibl_id",              limit: 4
  end

  add_index "bibls_legacy_identifiers", ["bibl_id"], name: "index_bibls_legacy_identifiers_on_bibl_id", using: :btree
  add_index "bibls_legacy_identifiers", ["legacy_identifier_id"], name: "index_bibls_legacy_identifiers_on_legacy_identifier_id", using: :btree

  create_table "component_types", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.string   "description",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "components_count", limit: 4
  end

  add_index "component_types", ["name"], name: "index_component_types_on_name", unique: true, using: :btree

  create_table "components", force: :cascade do |t|
    t.integer  "component_type_id",       limit: 4,     default: 0,    null: false
    t.integer  "parent_component_id",     limit: 4,     default: 0,    null: false
    t.string   "title",                   limit: 255
    t.string   "label",                   limit: 255
    t.string   "date",                    limit: 255
    t.text     "content_desc",            limit: 65535
    t.string   "idno",                    limit: 255
    t.string   "barcode",                 limit: 255
    t.integer  "seq_number",              limit: 4
    t.string   "pid",                     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "desc_metadata",           limit: 65535
    t.boolean  "discoverability",                       default: true
    t.integer  "indexing_scenario_id",    limit: 4
    t.text     "level",                   limit: 65535
    t.string   "ead_id_att",              limit: 255
    t.integer  "availability_policy_id",  limit: 4
    t.datetime "date_dl_ingest"
    t.datetime "date_dl_update"
    t.integer  "master_files_count",      limit: 4,     default: 0,    null: false
    t.string   "exemplar",                limit: 255
    t.string   "ancestry",                limit: 255
    t.string   "pids_depth_cache",        limit: 255
    t.string   "ead_id_atts_depth_cache", limit: 255
    t.integer  "followed_by_id",          limit: 4
    t.integer  "index_destination_id",    limit: 4
  end

  add_index "components", ["ancestry"], name: "index_components_on_ancestry", using: :btree
  add_index "components", ["availability_policy_id"], name: "index_components_on_availability_policy_id", using: :btree
  add_index "components", ["component_type_id"], name: "index_components_on_component_type_id", using: :btree
  add_index "components", ["followed_by_id"], name: "index_components_on_followed_by_id", using: :btree
  add_index "components", ["indexing_scenario_id"], name: "index_components_on_indexing_scenario_id", using: :btree

  create_table "components_containers", id: false, force: :cascade do |t|
    t.integer "container_id", limit: 4
    t.integer "component_id", limit: 4
  end

  add_index "components_containers", ["component_id"], name: "component_id", using: :btree
  add_index "components_containers", ["container_id"], name: "container_id", using: :btree

  create_table "components_legacy_identifiers", id: false, force: :cascade do |t|
    t.integer "component_id",         limit: 4
    t.integer "legacy_identifier_id", limit: 4
  end

  add_index "components_legacy_identifiers", ["component_id"], name: "component_id", using: :btree
  add_index "components_legacy_identifiers", ["legacy_identifier_id"], name: "legacy_identifier_id", using: :btree

  create_table "container_types", force: :cascade do |t|
    t.string "name",        limit: 255
    t.string "description", limit: 255
  end

  add_index "container_types", ["name"], name: "index_container_types_on_name", unique: true, using: :btree

  create_table "containers", force: :cascade do |t|
    t.string   "barcode",             limit: 255
    t.string   "container_type",      limit: 255
    t.string   "label",               limit: 255
    t.string   "sequence_no",         limit: 255
    t.integer  "parent_container_id", limit: 4,   default: 0, null: false
    t.integer  "legacy_component_id", limit: 4,   default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "container_type_id",   limit: 4
  end

  add_index "containers", ["container_type_id"], name: "containers_container_type_id_fk", using: :btree

  create_table "customers", force: :cascade do |t|
    t.integer  "department_id",      limit: 4
    t.integer  "academic_status_id", limit: 4,   default: 0, null: false
    t.string   "last_name",          limit: 255
    t.string   "first_name",         limit: 255
    t.string   "email",              limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "master_files_count", limit: 4,   default: 0
    t.integer  "orders_count",       limit: 4,   default: 0
  end

  add_index "customers", ["academic_status_id"], name: "index_customers_on_academic_status_id", using: :btree
  add_index "customers", ["department_id"], name: "index_customers_on_department_id", using: :btree
  add_index "customers", ["email"], name: "index_customers_on_email", using: :btree
  add_index "customers", ["first_name"], name: "index_customers_on_first_name", using: :btree
  add_index "customers", ["last_name"], name: "index_customers_on_last_name", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "departments", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "customers_count", limit: 4,   default: 0
  end

  add_index "departments", ["name"], name: "index_departments_on_name", unique: true, using: :btree

  create_table "image_tech_meta", force: :cascade do |t|
    t.integer  "master_file_id", limit: 4,                  default: 0, null: false
    t.string   "image_format",   limit: 255
    t.integer  "width",          limit: 4
    t.integer  "height",         limit: 4
    t.integer  "resolution",     limit: 4
    t.string   "color_space",    limit: 255
    t.integer  "depth",          limit: 4
    t.string   "compression",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "color_profile",  limit: 255
    t.string   "equipment",      limit: 255
    t.string   "software",       limit: 255
    t.string   "model",          limit: 255
    t.string   "exif_version",   limit: 255
    t.datetime "capture_date"
    t.integer  "iso",            limit: 4
    t.string   "exposure_bias",  limit: 255
    t.string   "exposure_time",  limit: 255
    t.string   "aperture",       limit: 255
    t.decimal  "focal_length",               precision: 10
  end

  add_index "image_tech_meta", ["master_file_id"], name: "index_image_tech_meta_on_master_file_id", using: :btree

  create_table "index_destinations", force: :cascade do |t|
    t.string   "nickname",         limit: 255
    t.string   "hostname",         limit: 255, default: "localhost"
    t.string   "port",             limit: 255, default: "8080"
    t.string   "protocol",         limit: 255, default: "http"
    t.string   "context",          limit: 255, default: "solr"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.integer  "bibls_count",      limit: 4
    t.integer  "units_count",      limit: 4
    t.integer  "components_count", limit: 4
  end

  create_table "indexing_scenarios", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.string   "pid",                limit: 255
    t.string   "datastream_name",    limit: 255
    t.string   "repository_url",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bibls_count",        limit: 4,   default: 0
    t.integer  "components_count",   limit: 4,   default: 0
    t.integer  "master_files_count", limit: 4,   default: 0
    t.integer  "units_count",        limit: 4,   default: 0
  end

  create_table "intended_uses", force: :cascade do |t|
    t.string   "description",                 limit: 255
    t.boolean  "is_internal_use_only",                    default: false, null: false
    t.boolean  "is_approved",                             default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "units_count",                 limit: 4,   default: 0
    t.string   "deliverable_format",          limit: 255
    t.string   "deliverable_resolution",      limit: 255
    t.string   "deliverable_resolution_unit", limit: 255
  end

  add_index "intended_uses", ["description"], name: "index_intended_uses_on_description", unique: true, using: :btree

  create_table "invoices", force: :cascade do |t|
    t.integer  "order_id",                limit: 4,        default: 0,     null: false
    t.datetime "date_invoice"
    t.text     "invoice_content",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "invoice_number",          limit: 4
    t.integer  "fee_amount_paid",         limit: 4
    t.datetime "date_fee_paid"
    t.datetime "date_second_notice_sent"
    t.text     "transmittal_number",      limit: 65535
    t.text     "notes",                   limit: 65535
    t.binary   "invoice_copy",            limit: 16777215
    t.boolean  "permanent_nonpayment",                     default: false
  end

  add_index "invoices", ["order_id"], name: "index_invoices_on_order_id", using: :btree

  create_table "job_statuses", force: :cascade do |t|
    t.string   "name",            limit: 255,                     null: false
    t.string   "status",          limit: 255, default: "pending", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer  "failures",        limit: 4,   default: 0,         null: false
    t.string   "error",           limit: 255
    t.integer  "originator_id",   limit: 4
    t.string   "originator_type", limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  create_table "legacy_identifiers", force: :cascade do |t|
    t.string   "label",             limit: 255
    t.string   "description",       limit: 255
    t.string   "legacy_identifier", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "legacy_identifiers", ["label"], name: "index_legacy_identifiers_on_label", using: :btree
  add_index "legacy_identifiers", ["legacy_identifier"], name: "index_legacy_identifiers_on_legacy_identifier", using: :btree

  create_table "legacy_identifiers_master_files", id: false, force: :cascade do |t|
    t.integer "legacy_identifier_id", limit: 4
    t.integer "master_file_id",       limit: 4
  end

  add_index "legacy_identifiers_master_files", ["legacy_identifier_id"], name: "index_legacy_identifiers_master_files_on_legacy_identifier_id", using: :btree
  add_index "legacy_identifiers_master_files", ["master_file_id"], name: "index_legacy_identifiers_master_files_on_master_file_id", using: :btree

  create_table "legacy_identifiers_units", id: false, force: :cascade do |t|
    t.integer "legacy_identifier_id", limit: 4
    t.integer "unit_id",              limit: 4
  end

  add_index "legacy_identifiers_units", ["unit_id", "legacy_identifier_id"], name: "units_legacy_ids_index", using: :btree

  create_table "master_files", force: :cascade do |t|
    t.integer  "unit_id",                limit: 4,     default: 0,     null: false
    t.integer  "component_id",           limit: 4
    t.string   "tech_meta_type",         limit: 255
    t.string   "filename",               limit: 255
    t.integer  "filesize",               limit: 4
    t.string   "title",                  limit: 255
    t.datetime "date_archived"
    t.string   "description",            limit: 255
    t.string   "pid",                    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "transcription_text",     limit: 65535
    t.text     "desc_metadata",          limit: 65535
    t.boolean  "discoverability",                      default: false
    t.string   "md5",                    limit: 255
    t.integer  "indexing_scenario_id",   limit: 4
    t.integer  "availability_policy_id", limit: 4
    t.integer  "use_right_id",           limit: 4
    t.datetime "date_dl_ingest"
    t.datetime "date_dl_update"
    t.boolean  "dpla",                                 default: false
    t.string   "creator_death_date",     limit: 255
    t.string   "creation_date",          limit: 255
    t.string   "primary_author",         limit: 255
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

  create_table "orders", force: :cascade do |t|
    t.integer  "customer_id",                        limit: 4,                             default: 0,     null: false
    t.integer  "agency_id",                          limit: 4
    t.string   "order_status",                       limit: 255
    t.boolean  "is_approved",                                                              default: false, null: false
    t.string   "order_title",                        limit: 255
    t.datetime "date_request_submitted"
    t.datetime "date_order_approved"
    t.datetime "date_deferred"
    t.datetime "date_canceled"
    t.datetime "date_permissions_given"
    t.datetime "date_started"
    t.date     "date_due"
    t.datetime "date_customer_notified"
    t.decimal  "fee_estimated",                                    precision: 7, scale: 2
    t.decimal  "fee_actual",                                       precision: 7, scale: 2
    t.string   "entered_by",                         limit: 255
    t.text     "special_instructions",               limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "staff_notes",                        limit: 65535
    t.text     "email",                              limit: 65535
    t.datetime "date_patron_deliverables_complete"
    t.datetime "date_archiving_complete"
    t.datetime "date_finalization_begun"
    t.datetime "date_fee_estimate_sent_to_customer"
    t.integer  "units_count",                        limit: 4,                             default: 0
    t.integer  "invoices_count",                     limit: 4,                             default: 0
    t.integer  "master_files_count",                 limit: 4,                             default: 0
  end

  add_index "orders", ["agency_id"], name: "index_orders_on_agency_id", using: :btree
  add_index "orders", ["customer_id"], name: "index_orders_on_customer_id", using: :btree
  add_index "orders", ["date_archiving_complete"], name: "index_orders_on_date_archiving_complete", using: :btree
  add_index "orders", ["date_due"], name: "index_orders_on_date_due", using: :btree
  add_index "orders", ["date_order_approved"], name: "index_orders_on_date_order_approved", using: :btree
  add_index "orders", ["date_request_submitted"], name: "index_orders_on_date_request_submitted", using: :btree
  add_index "orders", ["order_status"], name: "index_orders_on_order_status", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string "name", limit: 255, null: false
  end

  create_table "sql_reports", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "description", limit: 255
    t.text     "sql",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "staff_members", force: :cascade do |t|
    t.string   "computing_id", limit: 255
    t.string   "last_name",    limit: 255
    t.string   "first_name",   limit: 255
    t.boolean  "is_active",                default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",        limit: 255
    t.integer  "role_id",      limit: 4,   default: 1
  end

  add_index "staff_members", ["computing_id"], name: "index_staff_members_on_computing_id", unique: true, using: :btree

  create_table "units", force: :cascade do |t|
    t.integer  "order_id",                       limit: 4,     default: 0,     null: false
    t.integer  "bibl_id",                        limit: 4
    t.string   "unit_status",                    limit: 255
    t.datetime "date_materials_received"
    t.datetime "date_materials_returned"
    t.integer  "unit_extent_estimated",          limit: 4
    t.integer  "unit_extent_actual",             limit: 4
    t.text     "patron_source_url",              limit: 65535
    t.text     "special_instructions",           limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "intended_use_id",                limit: 4
    t.boolean  "exclude_from_dl",                              default: false, null: false
    t.text     "staff_notes",                    limit: 65535
    t.datetime "date_queued_for_ingest"
    t.datetime "date_archived"
    t.datetime "date_patron_deliverables_ready"
    t.boolean  "include_in_dl",                                default: false
    t.datetime "date_dl_deliverables_ready"
    t.boolean  "remove_watermark",                             default: false
    t.boolean  "master_file_discoverability",                  default: false
    t.integer  "indexing_scenario_id",           limit: 4
    t.boolean  "checked_out",                                  default: false
    t.integer  "availability_policy_id",         limit: 4
    t.integer  "master_files_count",             limit: 4,     default: 0
    t.integer  "index_destination_id",           limit: 4
  end

  add_index "units", ["availability_policy_id"], name: "index_units_on_availability_policy_id", using: :btree
  add_index "units", ["bibl_id"], name: "index_units_on_bibl_id", using: :btree
  add_index "units", ["date_archived"], name: "index_units_on_date_archived", using: :btree
  add_index "units", ["date_dl_deliverables_ready"], name: "index_units_on_date_dl_deliverables_ready", using: :btree
  add_index "units", ["indexing_scenario_id"], name: "index_units_on_indexing_scenario_id", using: :btree
  add_index "units", ["intended_use_id"], name: "index_units_on_intended_use_id", using: :btree
  add_index "units", ["order_id"], name: "index_units_on_order_id", using: :btree

  create_table "use_rights", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "bibls_count",        limit: 4,   default: 0
    t.integer  "master_files_count", limit: 4,   default: 0
  end

  add_index "use_rights", ["name"], name: "index_use_rights_on_name", unique: true, using: :btree

  add_foreign_key "bibls", "availability_policies", name: "bibls_availability_policy_id_fk"
  add_foreign_key "bibls", "indexing_scenarios", name: "bibls_indexing_scenario_id_fk"
  add_foreign_key "bibls", "use_rights", name: "bibls_use_right_id_fk"
  add_foreign_key "bibls_components", "bibls", name: "bibls_components_ibfk_1"
  add_foreign_key "bibls_components", "components", name: "bibls_components_ibfk_2"
  add_foreign_key "bibls_legacy_identifiers", "bibls", name: "bibls_legacy_identifiers_bibl_id_fk"
  add_foreign_key "bibls_legacy_identifiers", "legacy_identifiers", name: "bibls_legacy_identifiers_legacy_identifier_id_fk"
  add_foreign_key "components", "availability_policies", name: "components_availability_policy_id_fk"
  add_foreign_key "components", "component_types", name: "components_component_type_id_fk"
  add_foreign_key "components", "indexing_scenarios", name: "components_indexing_scenario_id_fk"
  add_foreign_key "components_containers", "components", name: "components_containers_ibfk_2"
  add_foreign_key "components_containers", "containers", name: "components_containers_ibfk_1"
  add_foreign_key "components_legacy_identifiers", "components", name: "components_legacy_identifiers_ibfk_1"
  add_foreign_key "components_legacy_identifiers", "legacy_identifiers", name: "components_legacy_identifiers_ibfk_2"
  add_foreign_key "containers", "container_types", name: "containers_container_type_id_fk"
  add_foreign_key "customers", "academic_statuses", name: "customers_academic_status_id_fk"
  add_foreign_key "customers", "departments", name: "customers_department_id_fk"
  add_foreign_key "image_tech_meta", "master_files", name: "image_tech_meta_master_file_id_fk"
  add_foreign_key "invoices", "orders", name: "invoices_order_id_fk"
  add_foreign_key "legacy_identifiers_master_files", "legacy_identifiers", name: "legacy_identifiers_master_files_legacy_identifier_id_fk"
  add_foreign_key "legacy_identifiers_master_files", "master_files", name: "legacy_identifiers_master_files_master_file_id_fk"
  add_foreign_key "master_files", "availability_policies", name: "master_files_availability_policy_id_fk"
  add_foreign_key "master_files", "components", name: "master_files_component_id_fk"
  add_foreign_key "master_files", "indexing_scenarios", name: "master_files_indexing_scenario_id_fk"
  add_foreign_key "master_files", "units", name: "master_files_unit_id_fk"
  add_foreign_key "master_files", "use_rights", name: "master_files_use_right_id_fk"
  add_foreign_key "orders", "agencies", name: "orders_agency_id_fk"
  add_foreign_key "orders", "customers", name: "orders_customer_id_fk"
  add_foreign_key "units", "availability_policies", name: "units_availability_policy_id_fk"
  add_foreign_key "units", "bibls", name: "units_bibl_id_fk"
  add_foreign_key "units", "indexing_scenarios", name: "units_indexing_scenario_id_fk"
  add_foreign_key "units", "intended_uses", name: "units_intended_use_id_fk"
  add_foreign_key "units", "orders", name: "units_order_id_fk"
end
