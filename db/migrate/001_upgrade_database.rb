class UpgradeDatabase < ActiveRecord::Migration
  def change
    remove_foreign_key :bibls, :name => "bibls_ibfk_2"
    remove_foreign_key :bibls, :name => "bibls_ibfk_1"

    remove_foreign_key :bibls_legacy_identifiers, :name => "bibls_legacy_identifiers_ibfk_1"
    remove_foreign_key :bibls_legacy_identifiers, :name => "bibls_legacy_identifiers_ibfk_2"

    remove_foreign_key :billing_addresses, :name => "billing_addresses_ibfk_1"
    remove_foreign_key :billing_addresses, :name => "billing_addresses_ibfk_2"

    remove_foreign_key :checkins, :name => "checkins_ibfk_1"
    remove_foreign_key :checkins, :name => "checkins_ibfk_2"

    remove_foreign_key :components, :name => "components_ibfk_3"
    remove_foreign_key :components, :name => "components_ibfk_1"
    remove_foreign_key :components, :name => "components_ibfk_2"

    remove_foreign_key :customers, :name => "customers_ibfk_1"
    remove_foreign_key :customers, :name => "customers_ibfk_2"
    remove_foreign_key :customers, :name => "customers_ibfk_3"

    remove_foreign_key :deliverables, :name => "deliverables_ibfk_1"
    remove_foreign_key :deliverables, :name => "deliverables_ibfk_2"

    remove_foreign_key :delivery_methods_orders, :name => "delivery_methods_orders_ibfk_1"
    remove_foreign_key :delivery_methods_orders, :name => "delivery_methods_orders_ibfk_2"

    remove_foreign_key :ead_refs_master_files, :name => "ead_refs_master_files_ibfk_1"
    remove_foreign_key :ead_refs_master_files, :name => "ead_refs_master_files_ibfk_2"

    remove_foreign_key :image_tech_meta, :name => "image_tech_meta_ibfk_1"

    remove_foreign_key :invoices, :name => "invoices_ibfk_1"

    remove_foreign_key :legacy_identifiers_master_files, :name => "legacy_identifiers_master_files_ibfk_1"
    remove_foreign_key :legacy_identifiers_master_files, :name => "legacy_identifiers_master_files_ibfk_2"

    remove_foreign_key :master_files, :name => "master_files_ibfk_3"
    remove_foreign_key :master_files, :name => "master_files_ibfk_1"
    remove_foreign_key :master_files, :name => "master_files_ibfk_2"

    remove_foreign_key :orders, :name => "orders_ibfk_1"
    remove_foreign_key :orders, :name => "orders_ibfk_2"
    remove_foreign_key :orders, :name => "orders_ibfk_3"

    remove_foreign_key :staff_members, :name => "staff_members_ibfk_1"

    remove_foreign_key :unit_import_sources, :name => "unit_import_sources_ibfk_1"

    remove_foreign_key :units, :name => "units_ibfk_1"
    remove_foreign_key :units, :name => "units_ibfk_2"
    remove_foreign_key :units, :name => "units_ibfk_3"
    remove_foreign_key :units, :name => "units_ibfk_4"
    remove_foreign_key :units, :name => "units_ibfk_5"
    remove_foreign_key :units, :name => "units_ibfk_6"
    remove_foreign_key :units, :name => "units_ibfk_7"
    remove_foreign_key :units, :name => "units_ibfk_8"
    remove_foreign_key :units, :name => "units_ibfk_9"

    drop_table :datastreams
   	drop_table :deliverables
    drop_table :deliverables_delivery_methods
    drop_table :delivery_methods_units
   	drop_table :image_specs
   	drop_table :tasks
    drop_table :text_tech_meta
   	drop_table :vendors
   	drop_table :vendor_batches
   	drop_table :workstations

    # Potentiall removable drop_table macros
    drop_table :access_controls
    drop_table :access_levels
    drop_table :content_models
    drop_table :countries
    drop_table :ead_refs
    drop_table :ead_refs_master_files
    drop_table :process_notification_refs
    drop_table :staff_members
    drop_table :record_exports
    drop_table :record_selection_refs
    drop_table :states

    # Transition uva_status to academic_status
    remove_index :uva_statuses, :name => "index_uva_statuses_on_name"
   	rename_table :uva_statuses, :academic_statuses
  end
end
