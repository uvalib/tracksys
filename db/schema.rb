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

ActiveRecord::Schema.define(:version => 20110930021435) do

  create_table "active_admin_comments", :force => true do |t|
    t.integer  "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "admin_users", :force => true do |t|
    t.string   "email",                                 :default => "", :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "agencies", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "is_billable",  :default => false, :null => false
    t.string   "last_name"
    t.string   "first_name"
    t.string   "address_1"
    t.string   "address_2"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "post_code"
    t.string   "phone"
    t.integer  "orders_count", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "agencies", ["name"], :name => "index_agencies_on_name", :unique => true

  create_table "archives", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "units_count", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "archives", ["name"], :name => "index_archives_on_name"

  create_table "automation_messages", :force => true do |t|
    t.integer  "unit_id"
    t.integer  "order_id"
    t.integer  "master_file_id"
    t.integer  "bibl_id"
    t.integer  "ead_ref_id"
    t.integer  "component_id"
    t.boolean  "active_error",   :default => false, :null => false
    t.string   "pid"
    t.string   "app"
    t.string   "processor"
    t.string   "message_type"
    t.string   "workflow_type"
    t.text     "message"
    t.text     "class_name"
    t.text     "backtrace"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "automation_messages", ["active_error"], :name => "index_automation_messages_on_active_error"
  add_index "automation_messages", ["bibl_id", "message_type"], :name => "index_automation_messages_on_bibl_id_and_message_type"
  add_index "automation_messages", ["bibl_id", "processor", "message_type"], :name => "index_by_bibl_processor_message_type"
  add_index "automation_messages", ["bibl_id", "processor", "workflow_type"], :name => "index_by_bibl_processor_workflow_type"
  add_index "automation_messages", ["bibl_id", "processor"], :name => "index_automation_messages_on_bibl_id_and_processor"
  add_index "automation_messages", ["bibl_id"], :name => "index_automation_messages_on_bibl_id"
  add_index "automation_messages", ["component_id", "message_type"], :name => "index_automation_messages_on_component_id_and_message_type"
  add_index "automation_messages", ["component_id", "processor", "message_type"], :name => "index_by_component_processor_message_type"
  add_index "automation_messages", ["component_id", "processor", "workflow_type"], :name => "index_by_component_processor_workflow_type"
  add_index "automation_messages", ["component_id", "processor"], :name => "index_automation_messages_on_component_id_and_processor"
  add_index "automation_messages", ["component_id"], :name => "index_automation_messages_on_component_id"
  add_index "automation_messages", ["ead_ref_id", "message_type"], :name => "index_automation_messages_on_ead_ref_id_and_message_type"
  add_index "automation_messages", ["ead_ref_id", "processor", "message_type"], :name => "index_by_ead_processor_message_type"
  add_index "automation_messages", ["ead_ref_id", "processor", "workflow_type"], :name => "index_by_ead_processor_workflow_type"
  add_index "automation_messages", ["ead_ref_id", "processor"], :name => "index_automation_messages_on_ead_ref_id_and_processor"
  add_index "automation_messages", ["ead_ref_id"], :name => "index_automation_messages_on_ead_ref_id"
  add_index "automation_messages", ["master_file_id", "message_type"], :name => "index_automation_messages_on_master_file_id_and_message_type"
  add_index "automation_messages", ["master_file_id", "processor", "message_type"], :name => "index_by_master_file_processor_message_type"
  add_index "automation_messages", ["master_file_id", "processor", "workflow_type"], :name => "index_by_master_file_processor_workflow_type"
  add_index "automation_messages", ["master_file_id", "processor"], :name => "index_automation_messages_on_master_file_id_and_processor"
  add_index "automation_messages", ["master_file_id"], :name => "index_automation_messages_on_master_file_id"
  add_index "automation_messages", ["message_type"], :name => "index_automation_messages_on_message_type"
  add_index "automation_messages", ["order_id", "message_type"], :name => "index_automation_messages_on_order_id_and_message_type"
  add_index "automation_messages", ["order_id", "processor", "message_type"], :name => "index_by_order_processor_message_type"
  add_index "automation_messages", ["order_id", "processor", "workflow_type"], :name => "index_by_order_processor_workflow_type"
  add_index "automation_messages", ["order_id", "processor"], :name => "index_automation_messages_on_order_id_and_processor"
  add_index "automation_messages", ["order_id"], :name => "index_automation_messages_on_order_id"
  add_index "automation_messages", ["processor", "message_type"], :name => "index_automation_messages_on_processor_and_message_type"
  add_index "automation_messages", ["processor"], :name => "index_automation_messages_on_processor"
  add_index "automation_messages", ["unit_id", "message_type"], :name => "index_automation_messages_on_unit_id_and_message_type"
  add_index "automation_messages", ["unit_id", "processor", "message_type"], :name => "index_by_unit_processor_message_type"
  add_index "automation_messages", ["unit_id", "processor", "workflow_type"], :name => "index_by_unit_processor_workflow_type"
  add_index "automation_messages", ["unit_id", "processor"], :name => "index_automation_messages_on_unit_id_and_processor"
  add_index "automation_messages", ["unit_id"], :name => "index_automation_messages_on_unit_id"
  add_index "automation_messages", ["workflow_type"], :name => "index_automation_messages_on_workflow_type"

  create_table "availability_policies", :force => true do |t|
    t.string   "name"
    t.string   "xacml_policy_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bibls", :force => true do |t|
    t.integer  "availability_policy_id"
    t.integer  "parent_bibl_id",                                  :default => 0,     :null => false
    t.datetime "date_external_update"
    t.string   "description"
    t.boolean  "is_approved",                                     :default => false, :null => false
    t.boolean  "is_collection",                                   :default => false, :null => false
    t.boolean  "is_in_catalog",                                   :default => false, :null => false
    t.boolean  "is_manuscript",                                   :default => false, :null => false
    t.boolean  "is_personal_item",                                :default => false, :null => false
    t.integer  "automation_messages_count",                       :default => 0
    t.integer  "orders_count",                                    :default => 0
    t.integer  "units_count",                                     :default => 0
    t.string   "barcode"
    t.string   "call_number"
    t.string   "catalog_id"
    t.text     "citation"
    t.integer  "copy"
    t.string   "creator_name"
    t.string   "creator_name_type"
    t.string   "genre"
    t.string   "issue"
    t.string   "location"
    t.string   "resource_type"
    t.string   "series_title"
    t.string   "title"
    t.string   "title_control"
    t.string   "volume"
    t.string   "year"
    t.string   "year_type"
    t.text     "dc"
    t.text     "desc_metadata"
    t.boolean  "discoverability",                                 :default => true,  :null => false
    t.string   "exemplar"
    t.string   "pid"
    t.text     "rels_ext"
    t.text     "rels_int"
    t.text     "solr",                      :limit => 2147483647
    t.datetime "date_ingested_into_dl"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bibls", ["availability_policy_id"], :name => "index_bibls_on_availability_policy_id"
  add_index "bibls", ["barcode"], :name => "index_bibls_on_barcode"
  add_index "bibls", ["call_number"], :name => "index_bibls_on_call_number"
  add_index "bibls", ["catalog_id"], :name => "index_bibls_on_catalog_id"
  add_index "bibls", ["parent_bibl_id"], :name => "index_bibls_on_parent_bibl_id"
  add_index "bibls", ["pid"], :name => "index_bibls_on_pid"
  add_index "bibls", ["title"], :name => "index_bibls_on_title"

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
    t.string   "organization"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "billing_addresses", ["agency_id"], :name => "index_billing_addresses_on_agency_id", :unique => true
  add_index "billing_addresses", ["customer_id"], :name => "index_billing_addresses_on_customer_id", :unique => true

  create_table "checkins", :force => true do |t|
    t.integer  "unit_id"
    t.integer  "admin_user_id"
    t.integer  "units_count",   :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "customers", :force => true do |t|
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
    t.string   "organization"
    t.integer  "orders_count",           :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "customers", ["email"], :name => "index_customers_on_email"
  add_index "customers", ["first_name"], :name => "index_customers_on_first_name"
  add_index "customers", ["heard_about_service_id"], :name => "index_customers_on_heard_about_service_id"
  add_index "customers", ["last_name"], :name => "index_customers_on_last_name"

  create_table "departments", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "departments", ["name"], :name => "index_departments_on_name"

  create_table "heard_about_resources", :force => true do |t|
    t.string   "description"
    t.boolean  "is_approved",          :default => false, :null => false
    t.boolean  "is_internal_use_only", :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "heard_about_resources", ["description"], :name => "index_heard_about_resources_on_description"

  create_table "heard_about_services", :force => true do |t|
    t.string   "description"
    t.boolean  "is_approved",          :default => false, :null => false
    t.boolean  "is_internal_use_only", :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "heard_about_services", ["description"], :name => "index_heard_about_services_on_description"

  create_table "invoices", :force => true do |t|
    t.integer  "order_id"
    t.datetime "date_invoice_sent"
    t.decimal  "fee_amount_paid",                              :precision => 10, :scale => 0
    t.datetime "date_second_invoice_sent"
    t.text     "notes"
    t.binary   "invoice_copy",             :limit => 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invoices", ["order_id"], :name => "index_invoices_on_order_id"

  create_table "legacy_identifiers", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "master_files", :force => true do |t|
    t.integer  "availability_policy_id"
    t.integer  "component_id"
    t.integer  "ead_ref_id"
    t.string   "tech_meta_type"
    t.integer  "unit_id",                                         :default => 0,     :null => false
    t.integer  "use_right_id"
    t.integer  "automation_messages_count"
    t.string   "description"
    t.string   "filename"
    t.integer  "filesize"
    t.string   "md5"
    t.string   "title"
    t.text     "dc"
    t.text     "desc_metadata"
    t.boolean  "discoverability",                                 :default => false, :null => false
    t.boolean  "locked_desc_metadata",                            :default => false, :null => false
    t.string   "pid"
    t.text     "rels_ext"
    t.text     "rels_int"
    t.text     "solr",                      :limit => 2147483647
    t.text     "transcription_text"
    t.datetime "date_ingested_into_dl"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "master_files", ["availability_policy_id"], :name => "index_master_files_on_availability_policy_id"
  add_index "master_files", ["component_id"], :name => "index_master_files_on_component_id"
  add_index "master_files", ["description"], :name => "index_master_files_on_description", :length => {"description"=>30}
  add_index "master_files", ["ead_ref_id"], :name => "index_master_files_on_ead_ref_id"
  add_index "master_files", ["filename"], :name => "index_master_files_on_filename"
  add_index "master_files", ["pid"], :name => "index_master_files_on_pid"
  add_index "master_files", ["tech_meta_type"], :name => "index_master_files_on_tech_meta_type"
  add_index "master_files", ["title"], :name => "index_master_files_on_title"
  add_index "master_files", ["transcription_text"], :name => "index_master_files_on_transcription_text", :length => {"transcription_text"=>30}
  add_index "master_files", ["unit_id"], :name => "index_master_files_on_unit_id"
  add_index "master_files", ["use_right_id"], :name => "index_master_files_on_use_right_id"

  create_table "orders", :force => true do |t|
    t.integer  "agency_id"
    t.integer  "customer_id",                                                      :default => 0,     :null => false
    t.integer  "dvd_delivery_location_id"
    t.integer  "units_count",                                                      :default => 0
    t.integer  "invoices_count",                                                   :default => 0
    t.integer  "automation_messages_count",                                        :default => 0
    t.datetime "date_canceled"
    t.datetime "date_deferred"
    t.date     "date_due"
    t.datetime "date_fee_estimate_sent_to_customer"
    t.datetime "date_order_approved"
    t.datetime "date_permissions_given"
    t.datetime "date_started"
    t.datetime "date_request_submitted"
    t.string   "entered_by"
    t.decimal  "fee_actual",                         :precision => 7, :scale => 2
    t.decimal  "fee_estimated",                      :precision => 7, :scale => 2
    t.boolean  "is_approved",                                                      :default => false, :null => false
    t.string   "order_status"
    t.string   "order_title"
    t.text     "special_instructions"
    t.text     "staff_notes"
    t.datetime "date_archiving_complete"
    t.datetime "date_customer_notified"
    t.datetime "date_finalization_begun"
    t.datetime "date_patron_deliverables_complete"
    t.text     "email"
    t.datetime "created_at"
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

  create_table "requests", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "units", :force => true do |t|
    t.integer  "archive_id"
    t.integer  "availability_policy_id"
    t.integer  "bibl_id"
    t.integer  "heard_about_resource_id"
    t.integer  "intended_use_id"
    t.integer  "order_id",                       :default => 0,     :null => false
    t.integer  "use_right_id"
    t.integer  "master_files_count",             :default => 0
    t.integer  "automation_messages_count",      :default => 0
    t.datetime "date_archived"
    t.datetime "date_materials_received"
    t.datetime "date_materials_returned"
    t.datetime "date_patron_deliverables_ready"
    t.string   "deliverable_format"
    t.string   "deliverable_resolution"
    t.string   "deliverable_resolution_unit"
    t.string   "patron_source_url"
    t.boolean  "remove_watermark",               :default => false, :null => false
    t.text     "special_instructions"
    t.text     "staff_notes"
    t.integer  "unit_extent_estimated"
    t.integer  "unit_extent_actual"
    t.string   "unit_status"
    t.datetime "date_queued_for_ingest"
    t.datetime "date_dl_deliverables_ready"
    t.boolean  "master_file_discoverability",    :default => false, :null => false
    t.boolean  "exclude_from_dl",                :default => false, :null => false
    t.boolean  "include_in_dl",                  :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "units", ["archive_id"], :name => "index_units_on_archive_id"
  add_index "units", ["availability_policy_id"], :name => "index_units_on_availability_policy_id"
  add_index "units", ["bibl_id"], :name => "index_units_on_bibl_id"
  add_index "units", ["date_archived"], :name => "index_units_on_date_archived"
  add_index "units", ["date_dl_deliverables_ready"], :name => "index_units_on_date_dl_deliverables_ready"
  add_index "units", ["heard_about_resource_id"], :name => "index_units_on_heard_about_resource_id"
  add_index "units", ["intended_use_id"], :name => "index_units_on_intended_use_id"
  add_index "units", ["order_id"], :name => "index_units_on_order_id"
  add_index "units", ["use_right_id"], :name => "index_units_on_use_right_id"

  create_table "uva_statuses", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
