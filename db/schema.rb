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

ActiveRecord::Schema.define(version: 20171106161113) do

  create_table "academic_statuses", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "customers_count", default: 0
    t.index ["name"], name: "index_academic_statuses_on_name", unique: true
  end

  create_table "active_admin_comments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "resource_id", null: false
    t.string "resource_type", null: false
    t.integer "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "namespace"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_admin_notes_on_resource_type_and_resource_id"
  end

  create_table "addresses", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "addressable_id", null: false
    t.string "addressable_type", limit: 20, null: false
    t.string "address_type", limit: 20, null: false
    t.string "last_name"
    t.string "first_name"
    t.string "address_1"
    t.string "address_2"
    t.string "city"
    t.string "state"
    t.string "country"
    t.string "post_code"
    t.string "phone"
    t.string "organization"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "agencies", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "ancestry"
    t.string "names_depth_cache"
    t.integer "orders_count", default: 0
    t.index ["ancestry"], name: "index_agencies_on_ancestry"
    t.index ["name"], name: "index_agencies_on_name", unique: true
  end

  create_table "assignments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "project_id"
    t.integer "step_id"
    t.integer "staff_member_id"
    t.datetime "assigned_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer "status", default: 0
    t.integer "duration_minutes"
    t.index ["project_id"], name: "index_assignments_on_project_id"
    t.index ["staff_member_id"], name: "index_assignments_on_staff_member_id"
    t.index ["step_id"], name: "index_assignments_on_step_id"
  end

  create_table "attachments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "unit_id"
    t.string "filename"
    t.string "md5"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_id"], name: "index_attachments_on_unit_id"
  end

  create_table "audit_events", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "staff_member_id"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "event"
    t.string "details"
    t.datetime "created_at"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_events_on_auditable_type_and_auditable_id"
    t.index ["staff_member_id"], name: "index_audit_events_on_staff_member_id"
  end

  create_table "availability_policies", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.integer "metadata_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pid"
  end

  create_table "categories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.integer "projects_count", default: 0
  end

  create_table "collection_facets", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "component_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "components_count"
    t.index ["name"], name: "index_component_types_on_name", unique: true
  end

  create_table "components", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "component_type_id", default: 0, null: false
    t.integer "parent_component_id", default: 0, null: false
    t.string "title"
    t.string "label"
    t.string "date"
    t.text "content_desc"
    t.string "idno"
    t.string "barcode"
    t.integer "seq_number"
    t.string "pid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "desc_metadata"
    t.boolean "discoverability", default: true
    t.text "level"
    t.string "ead_id_att"
    t.datetime "date_dl_ingest"
    t.datetime "date_dl_update"
    t.integer "master_files_count", default: 0, null: false
    t.string "exemplar"
    t.string "ancestry"
    t.string "pids_depth_cache"
    t.string "ead_id_atts_depth_cache"
    t.integer "followed_by_id"
    t.index ["ancestry"], name: "index_components_on_ancestry"
    t.index ["component_type_id"], name: "index_components_on_component_type_id"
    t.index ["followed_by_id"], name: "index_components_on_followed_by_id"
    t.index ["pid"], name: "index_components_on_pid"
  end

  create_table "container_types", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
  end

  create_table "customers", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "department_id"
    t.integer "academic_status_id", default: 0, null: false
    t.string "last_name"
    t.string "first_name"
    t.string "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "master_files_count", default: 0
    t.integer "orders_count", default: 0
    t.index ["academic_status_id"], name: "index_customers_on_academic_status_id"
    t.index ["department_id"], name: "index_customers_on_department_id"
    t.index ["email"], name: "index_customers_on_email"
    t.index ["first_name"], name: "index_customers_on_first_name"
    t.index ["last_name"], name: "index_customers_on_last_name"
  end

  create_table "delayed_jobs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "departments", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "customers_count", default: 0
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "equipment", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "type"
    t.string "name"
    t.string "serial_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
  end

  create_table "genres", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
  end

  create_table "image_tech_meta", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "master_file_id", default: 0, null: false
    t.string "image_format"
    t.integer "width"
    t.integer "height"
    t.integer "resolution"
    t.string "color_space"
    t.integer "depth"
    t.string "compression"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "color_profile"
    t.string "equipment"
    t.string "software"
    t.string "model"
    t.string "exif_version"
    t.datetime "capture_date"
    t.integer "iso"
    t.string "exposure_bias"
    t.string "exposure_time"
    t.string "aperture"
    t.decimal "focal_length", precision: 10
    t.index ["master_file_id"], name: "index_image_tech_meta_on_master_file_id"
  end

  create_table "intended_uses", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "description"
    t.boolean "is_internal_use_only", default: false, null: false
    t.boolean "is_approved", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "units_count", default: 0
    t.string "deliverable_format"
    t.string "deliverable_resolution"
    t.index ["description"], name: "index_intended_uses_on_description", unique: true
  end

  create_table "invoices", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "order_id", default: 0, null: false
    t.datetime "date_invoice"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "invoice_number"
    t.integer "fee_amount_paid"
    t.datetime "date_fee_paid"
    t.datetime "date_second_notice_sent"
    t.text "transmittal_number"
    t.text "notes"
    t.boolean "permanent_nonpayment", default: false
    t.index ["order_id"], name: "index_invoices_on_order_id"
  end

  create_table "job_statuses", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name", null: false
    t.string "status", default: "pending", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer "failures", default: 0, null: false
    t.string "error"
    t.integer "originator_id"
    t.string "originator_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["originator_type", "originator_id"], name: "index_job_statuses_on_originator_type_and_originator_id"
  end

  create_table "locations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "container_type_id"
    t.string "container_id", null: false
    t.string "folder_id", null: false
    t.index ["container_type_id"], name: "index_locations_on_container_type_id"
  end

  create_table "master_file_locations", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "location_id"
    t.bigint "master_file_id"
    t.index ["location_id"], name: "index_master_file_locations_on_location_id"
    t.index ["master_file_id"], name: "index_master_file_locations_on_master_file_id"
  end

  create_table "master_files", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "unit_id", default: 0, null: false
    t.integer "component_id"
    t.string "filename"
    t.integer "filesize"
    t.string "title"
    t.datetime "date_archived"
    t.text "description"
    t.string "pid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "transcription_text"
    t.string "md5"
    t.datetime "date_dl_ingest"
    t.datetime "date_dl_update"
    t.string "creator_death_date"
    t.string "creation_date"
    t.string "primary_author"
    t.integer "metadata_id"
    t.integer "original_mf_id"
    t.datetime "deaccessioned_at"
    t.text "deaccession_note"
    t.integer "deaccessioned_by_id"
    t.integer "text_source"
    t.index ["component_id"], name: "index_master_files_on_component_id"
    t.index ["date_dl_ingest"], name: "index_master_files_on_date_dl_ingest"
    t.index ["date_dl_update"], name: "index_master_files_on_date_dl_update"
    t.index ["filename"], name: "index_master_files_on_filename"
    t.index ["metadata_id"], name: "index_master_files_on_metadata_id"
    t.index ["original_mf_id"], name: "index_master_files_on_original_mf_id"
    t.index ["pid"], name: "index_master_files_on_pid"
    t.index ["title"], name: "index_master_files_on_title"
    t.index ["unit_id"], name: "index_master_files_on_unit_id"
  end

  create_table "metadata", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.boolean "is_approved", default: false, null: false
    t.boolean "is_personal_item", default: false, null: false
    t.boolean "is_manuscript", default: false, null: false
    t.text "title"
    t.string "creator_name"
    t.string "catalog_key"
    t.string "barcode"
    t.string "call_number"
    t.string "pid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "exemplar"
    t.integer "parent_metadata_id", default: 0, null: false
    t.text "desc_metadata"
    t.boolean "discoverability", default: true
    t.datetime "date_dl_ingest"
    t.datetime "date_dl_update"
    t.integer "units_count", default: 0
    t.integer "availability_policy_id"
    t.integer "use_right_id"
    t.boolean "dpla", default: false
    t.string "collection_facet"
    t.string "type", default: "SirsiMetadata"
    t.string "external_system"
    t.string "external_uri"
    t.string "supplemental_system"
    t.string "supplemental_uri"
    t.integer "genre_id"
    t.integer "resource_type_id"
    t.string "collection_id"
    t.integer "ocr_hint_id"
    t.string "ocr_language_hint"
    t.index ["availability_policy_id"], name: "index_metadata_on_availability_policy_id"
    t.index ["barcode"], name: "index_metadata_on_barcode"
    t.index ["call_number"], name: "index_metadata_on_call_number"
    t.index ["catalog_key"], name: "index_metadata_on_catalog_key"
    t.index ["dpla"], name: "index_metadata_on_dpla"
    t.index ["genre_id"], name: "index_metadata_on_genre_id"
    t.index ["ocr_hint_id"], name: "index_metadata_on_ocr_hint_id"
    t.index ["parent_metadata_id"], name: "index_metadata_on_parent_metadata_id"
    t.index ["pid"], name: "index_metadata_on_pid"
    t.index ["resource_type_id"], name: "index_metadata_on_resource_type_id"
    t.index ["use_right_id"], name: "index_metadata_on_use_right_id"
  end

  create_table "notes", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "staff_member_id"
    t.integer "project_id"
    t.text "note"
    t.integer "note_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "step_id"
    t.index ["project_id"], name: "index_notes_on_project_id"
    t.index ["staff_member_id"], name: "index_notes_on_staff_member_id"
    t.index ["step_id"], name: "index_notes_on_step_id"
  end

  create_table "notes_problems", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "note_id"
    t.bigint "problem_id"
    t.index ["note_id"], name: "index_notes_problems_on_note_id"
    t.index ["problem_id"], name: "index_notes_problems_on_problem_id"
  end

  create_table "ocr_hints", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.boolean "ocr_candidate", default: true
  end

  create_table "orders", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "customer_id", default: 0, null: false
    t.integer "agency_id"
    t.string "order_status"
    t.boolean "is_approved", default: false, null: false
    t.string "order_title"
    t.datetime "date_request_submitted"
    t.datetime "date_order_approved"
    t.datetime "date_deferred"
    t.datetime "date_canceled"
    t.date "date_due"
    t.datetime "date_customer_notified"
    t.decimal "fee_estimated", precision: 7, scale: 2
    t.decimal "fee_actual", precision: 7, scale: 2
    t.text "special_instructions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "staff_notes"
    t.text "email"
    t.datetime "date_patron_deliverables_complete"
    t.datetime "date_archiving_complete"
    t.datetime "date_finalization_begun"
    t.datetime "date_fee_estimate_sent_to_customer"
    t.integer "units_count", default: 0
    t.integer "invoices_count", default: 0
    t.integer "master_files_count", default: 0
    t.datetime "date_completed"
    t.index ["agency_id"], name: "index_orders_on_agency_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["date_archiving_complete"], name: "index_orders_on_date_archiving_complete"
    t.index ["date_due"], name: "index_orders_on_date_due"
    t.index ["date_order_approved"], name: "index_orders_on_date_order_approved"
    t.index ["date_request_submitted"], name: "index_orders_on_date_request_submitted"
    t.index ["order_status"], name: "index_orders_on_order_status"
  end

  create_table "problems", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "label"
  end

  create_table "project_equipment", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "project_id"
    t.integer "equipment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["equipment_id"], name: "index_project_equipment_on_equipment_id"
    t.index ["project_id"], name: "index_project_equipment_on_project_id"
  end

  create_table "projects", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "workflow_id"
    t.integer "unit_id"
    t.integer "owner_id"
    t.integer "current_step_id"
    t.integer "priority", default: 0
    t.date "due_on"
    t.integer "item_condition"
    t.datetime "added_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer "category_id"
    t.string "viu_number"
    t.integer "capture_resolution"
    t.integer "resized_resolution"
    t.string "resolution_note"
    t.integer "workstation_id"
    t.text "condition_note"
    t.index ["category_id"], name: "index_projects_on_category_id"
    t.index ["unit_id"], name: "index_projects_on_unit_id"
    t.index ["workflow_id"], name: "index_projects_on_workflow_id"
    t.index ["workstation_id"], name: "index_projects_on_workstation_id"
  end

  create_table "resource_types", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
  end

  create_table "sirsi_metadata_components", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "sirsi_metadata_id"
    t.integer "component_id"
    t.index ["component_id"], name: "component_id"
    t.index ["sirsi_metadata_id"], name: "bibl_id"
  end

  create_table "staff_members", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "computing_id"
    t.string "last_name"
    t.string "first_name"
    t.boolean "is_active", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "email"
    t.integer "role", default: 0
    t.index ["computing_id"], name: "index_staff_members_on_computing_id", unique: true
  end

  create_table "staff_skills", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "staff_member_id"
    t.integer "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["category_id"], name: "index_staff_skills_on_category_id"
    t.index ["staff_member_id"], name: "index_staff_skills_on_staff_member_id"
  end

  create_table "statistics", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "group"
  end

  create_table "steps", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "step_type", default: 3
    t.string "name"
    t.text "description"
    t.string "start_dir"
    t.string "finish_dir"
    t.integer "workflow_id"
    t.integer "next_step_id"
    t.integer "fail_step_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "owner_type", default: 0
    t.boolean "manual", default: false
    t.index ["fail_step_id"], name: "index_steps_on_fail_step_id"
    t.index ["next_step_id"], name: "index_steps_on_next_step_id"
    t.index ["workflow_id"], name: "index_steps_on_workflow_id"
  end

  create_table "units", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "order_id", default: 0, null: false
    t.integer "metadata_id"
    t.string "unit_status"
    t.datetime "date_materials_received"
    t.datetime "date_materials_returned"
    t.integer "unit_extent_estimated"
    t.integer "unit_extent_actual"
    t.text "patron_source_url"
    t.text "special_instructions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "intended_use_id"
    t.text "staff_notes"
    t.datetime "date_archived"
    t.datetime "date_patron_deliverables_ready"
    t.boolean "include_in_dl", default: false
    t.datetime "date_dl_deliverables_ready"
    t.boolean "remove_watermark", default: false
    t.boolean "checked_out", default: false
    t.integer "master_files_count", default: 0
    t.boolean "complete_scan", default: false
    t.boolean "reorder", default: false
    t.boolean "throw_away", default: false
    t.boolean "ocr_master_files", default: false
    t.index ["date_archived"], name: "index_units_on_date_archived"
    t.index ["date_dl_deliverables_ready"], name: "index_units_on_date_dl_deliverables_ready"
    t.index ["intended_use_id"], name: "index_units_on_intended_use_id"
    t.index ["metadata_id"], name: "index_units_on_metadata_id"
    t.index ["order_id"], name: "index_units_on_order_id"
  end

  create_table "use_rights", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "metadata_count", default: 0
    t.string "uri"
    t.text "statement"
    t.boolean "commercial_use", default: false
    t.boolean "educational_use", default: false
    t.boolean "modifications", default: false
    t.index ["name"], name: "index_use_rights_on_name", unique: true
  end

  create_table "workflows", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "base_directory", default: "/Users/lf6f/dev/tracksys-dev/sandbox/digiserv-production"
    t.boolean "active", default: true
  end

  create_table "workstation_equipment", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "workstation_id"
    t.integer "equipment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["equipment_id"], name: "index_workstation_equipment_on_equipment_id"
    t.index ["workstation_id"], name: "index_workstation_equipment_on_workstation_id"
  end

  create_table "workstations", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
  end

  add_foreign_key "attachments", "units"
  add_foreign_key "components", "component_types", name: "components_component_type_id_fk"
  add_foreign_key "customers", "academic_statuses", name: "customers_academic_status_id_fk"
  add_foreign_key "customers", "departments", name: "customers_department_id_fk"
  add_foreign_key "image_tech_meta", "master_files", name: "image_tech_meta_master_file_id_fk"
  add_foreign_key "invoices", "orders", name: "invoices_order_id_fk"
  add_foreign_key "master_files", "components", name: "master_files_component_id_fk"
  add_foreign_key "master_files", "units", name: "master_files_unit_id_fk"
  add_foreign_key "metadata", "availability_policies", name: "bibls_availability_policy_id_fk"
  add_foreign_key "metadata", "ocr_hints"
  add_foreign_key "metadata", "use_rights", name: "bibls_use_right_id_fk"
  add_foreign_key "orders", "agencies", name: "orders_agency_id_fk"
  add_foreign_key "orders", "customers", name: "orders_customer_id_fk"
  add_foreign_key "sirsi_metadata_components", "components", name: "sirsi_metadata_components_ibfk_2"
  add_foreign_key "units", "intended_uses", name: "units_intended_use_id_fk"
  add_foreign_key "units", "orders", name: "units_order_id_fk"
end
