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

ActiveRecord::Schema.define(version: 20161103195323) do

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

  create_table "attachments", force: :cascade do |t|
    t.integer  "unit_id",     limit: 4
    t.string   "filename",    limit: 255
    t.string   "md5",         limit: 255
    t.text     "description", limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "attachments", ["unit_id"], name: "index_attachments_on_unit_id", using: :btree

  create_table "availability_policies", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.integer  "metadata_count", limit: 4,   default: 0
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "pid",            limit: 255
  end

  create_table "collection_facets", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

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
    t.datetime "date_dl_ingest"
    t.datetime "date_dl_update"
    t.integer  "master_files_count",      limit: 4,     default: 0,    null: false
    t.string   "exemplar",                limit: 255
    t.string   "ancestry",                limit: 255
    t.string   "pids_depth_cache",        limit: 255
    t.string   "ead_id_atts_depth_cache", limit: 255
    t.integer  "followed_by_id",          limit: 4
  end

  add_index "components", ["ancestry"], name: "index_components_on_ancestry", using: :btree
  add_index "components", ["component_type_id"], name: "index_components_on_component_type_id", using: :btree
  add_index "components", ["followed_by_id"], name: "index_components_on_followed_by_id", using: :btree
  add_index "components", ["indexing_scenario_id"], name: "index_components_on_indexing_scenario_id", using: :btree

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

  create_table "indexing_scenarios", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "metadata_count",   limit: 4,   default: 0
    t.integer  "components_count", limit: 4,   default: 0
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
    t.integer  "order_id",                limit: 4,     default: 0,     null: false
    t.datetime "date_invoice"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "invoice_number",          limit: 4
    t.integer  "fee_amount_paid",         limit: 4
    t.datetime "date_fee_paid"
    t.datetime "date_second_notice_sent"
    t.text     "transmittal_number",      limit: 65535
    t.text     "notes",                   limit: 65535
    t.boolean  "permanent_nonpayment",                  default: false
  end

  add_index "invoices", ["order_id"], name: "index_invoices_on_order_id", using: :btree

  create_table "items", force: :cascade do |t|
    t.string   "pid",          limit: 255
    t.string   "external_uri", limit: 255
    t.integer  "unit_id",      limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "items", ["unit_id"], name: "index_items_on_unit_id", using: :btree

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

  create_table "master_files", force: :cascade do |t|
    t.integer  "unit_id",            limit: 4,     default: 0, null: false
    t.integer  "component_id",       limit: 4
    t.string   "filename",           limit: 255
    t.integer  "filesize",           limit: 4
    t.string   "title",              limit: 255
    t.datetime "date_archived"
    t.text     "description",        limit: 65535
    t.string   "pid",                limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "transcription_text", limit: 65535
    t.string   "md5",                limit: 255
    t.datetime "date_dl_ingest"
    t.datetime "date_dl_update"
    t.string   "creator_death_date", limit: 255
    t.string   "creation_date",      limit: 255
    t.string   "primary_author",     limit: 255
    t.integer  "item_id",            limit: 4
    t.integer  "metadata_id",        limit: 4
  end

  add_index "master_files", ["component_id"], name: "index_master_files_on_component_id", using: :btree
  add_index "master_files", ["date_dl_ingest"], name: "index_master_files_on_date_dl_ingest", using: :btree
  add_index "master_files", ["date_dl_update"], name: "index_master_files_on_date_dl_update", using: :btree
  add_index "master_files", ["filename"], name: "index_master_files_on_filename", using: :btree
  add_index "master_files", ["item_id"], name: "index_master_files_on_item_id", using: :btree
  add_index "master_files", ["metadata_id"], name: "index_master_files_on_metadata_id", using: :btree
  add_index "master_files", ["pid"], name: "index_master_files_on_pid", using: :btree
  add_index "master_files", ["title"], name: "index_master_files_on_title", using: :btree
  add_index "master_files", ["unit_id"], name: "index_master_files_on_unit_id", using: :btree

  create_table "metadata", force: :cascade do |t|
    t.boolean  "is_approved",                          default: false,           null: false
    t.boolean  "is_personal_item",                     default: false,           null: false
    t.string   "resource_type",          limit: 255
    t.string   "genre",                  limit: 255
    t.boolean  "is_manuscript",                        default: false,           null: false
    t.boolean  "is_collection",                        default: false,           null: false
    t.text     "title",                  limit: 65535
    t.string   "creator_name",           limit: 255
    t.string   "catalog_key",            limit: 255
    t.string   "barcode",                limit: 255
    t.string   "call_number",            limit: 255
    t.string   "pid",                    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "exemplar",               limit: 255
    t.integer  "parent_bibl_id",         limit: 4,     default: 0,               null: false
    t.text     "desc_metadata",          limit: 65535
    t.boolean  "discoverability",                      default: true
    t.integer  "indexing_scenario_id",   limit: 4
    t.datetime "date_dl_ingest"
    t.datetime "date_dl_update"
    t.integer  "units_count",            limit: 4,     default: 0
    t.integer  "availability_policy_id", limit: 4
    t.integer  "use_right_id",           limit: 4
    t.boolean  "dpla",                                 default: false
    t.string   "collection_facet",       limit: 255
    t.string   "type",                   limit: 255,   default: "SirsiMetadata"
    t.text     "external_attributes",    limit: 65535
  end

  add_index "metadata", ["availability_policy_id"], name: "index_metadata_on_availability_policy_id", using: :btree
  add_index "metadata", ["barcode"], name: "index_metadata_on_barcode", using: :btree
  add_index "metadata", ["call_number"], name: "index_metadata_on_call_number", using: :btree
  add_index "metadata", ["catalog_key"], name: "index_metadata_on_catalog_key", using: :btree
  add_index "metadata", ["dpla"], name: "index_metadata_on_dpla", using: :btree
  add_index "metadata", ["indexing_scenario_id"], name: "index_metadata_on_indexing_scenario_id", using: :btree
  add_index "metadata", ["parent_bibl_id"], name: "index_metadata_on_parent_bibl_id", using: :btree
  add_index "metadata", ["pid"], name: "index_metadata_on_pid", using: :btree
  add_index "metadata", ["use_right_id"], name: "index_metadata_on_use_right_id", using: :btree

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

  create_table "sirsi_metadata_components", id: false, force: :cascade do |t|
    t.integer "sirsi_metadata_id", limit: 4
    t.integer "component_id",      limit: 4
  end

  add_index "sirsi_metadata_components", ["component_id"], name: "component_id", using: :btree
  add_index "sirsi_metadata_components", ["sirsi_metadata_id"], name: "bibl_id", using: :btree

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
    t.integer  "metadata_id",                    limit: 4
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
    t.text     "staff_notes",                    limit: 65535
    t.datetime "date_queued_for_ingest"
    t.datetime "date_archived"
    t.datetime "date_patron_deliverables_ready"
    t.boolean  "include_in_dl",                                default: false
    t.datetime "date_dl_deliverables_ready"
    t.boolean  "remove_watermark",                             default: false
    t.boolean  "checked_out",                                  default: false
    t.integer  "master_files_count",             limit: 4,     default: 0
    t.boolean  "complete_scan",                                default: false
  end

  add_index "units", ["date_archived"], name: "index_units_on_date_archived", using: :btree
  add_index "units", ["date_dl_deliverables_ready"], name: "index_units_on_date_dl_deliverables_ready", using: :btree
  add_index "units", ["intended_use_id"], name: "index_units_on_intended_use_id", using: :btree
  add_index "units", ["metadata_id"], name: "index_units_on_metadata_id", using: :btree
  add_index "units", ["order_id"], name: "index_units_on_order_id", using: :btree

  create_table "use_rights", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "metadata_count", limit: 4,   default: 0
    t.string   "uri",            limit: 255
  end

  add_index "use_rights", ["name"], name: "index_use_rights_on_name", unique: true, using: :btree

  add_foreign_key "attachments", "units"
  add_foreign_key "components", "component_types", name: "components_component_type_id_fk"
  add_foreign_key "components", "indexing_scenarios", name: "components_indexing_scenario_id_fk"
  add_foreign_key "customers", "academic_statuses", name: "customers_academic_status_id_fk"
  add_foreign_key "customers", "departments", name: "customers_department_id_fk"
  add_foreign_key "image_tech_meta", "master_files", name: "image_tech_meta_master_file_id_fk"
  add_foreign_key "invoices", "orders", name: "invoices_order_id_fk"
  add_foreign_key "master_files", "components", name: "master_files_component_id_fk"
  add_foreign_key "master_files", "units", name: "master_files_unit_id_fk"
  add_foreign_key "metadata", "availability_policies", name: "bibls_availability_policy_id_fk"
  add_foreign_key "metadata", "indexing_scenarios", name: "bibls_indexing_scenario_id_fk"
  add_foreign_key "metadata", "use_rights", name: "bibls_use_right_id_fk"
  add_foreign_key "orders", "agencies", name: "orders_agency_id_fk"
  add_foreign_key "orders", "customers", name: "orders_customer_id_fk"
  add_foreign_key "sirsi_metadata_components", "components", name: "sirsi_metadata_components_ibfk_2"
  add_foreign_key "sirsi_metadata_components", "metadata", column: "sirsi_metadata_id", name: "sirsi_metadata_components_ibfk_1"
  add_foreign_key "units", "intended_uses", name: "units_intended_use_id_fk"
  add_foreign_key "units", "metadata", column: "metadata_id", name: "units_bibl_id_fk"
  add_foreign_key "units", "orders", name: "units_order_id_fk"
end
