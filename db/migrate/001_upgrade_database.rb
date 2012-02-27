class UpgradeDatabase < ActiveRecord::Migration
  def change
    change_table(:bibls, :bulk => true) do |t|
      t.remove_foreign_key :name => 'bibls_ibfk_2'
      t.remove_foreign_key :name => 'bibls_ibfk_1'
    end

    change_table(:bibls_legacy_identifiers, :bulk => true) do |t|
      t.remove_foreign_key :name => "bibls_legacy_identifiers_ibfk_1"
      t.remove_foreign_key :name => "bibls_legacy_identifiers_ibfk_2"
    end

    change_table(:billing_addresses, :bulk => true) do |t|
      t.remove_foreign_key :name => "billing_addresses_ibfk_1"
      t.remove_foreign_key :name => "billing_addresses_ibfk_2"
    end

    change_table(:checkins, :bulk => true) do |t|
      t.remove_foreign_key :name => "checkins_ibfk_1"
      t.remove_foreign_key :name => "checkins_ibfk_2"
    end

    change_table(:components, :bulk => true) do |t|
      t.remove_foreign_key :name => "components_ibfk_3"
      t.remove_foreign_key :name => "components_ibfk_1"
      t.remove_foreign_key :name => "components_ibfk_2"
    end

    change_table(:customers, :bulk => true) do |t|
      remove_foreign_key :customers, :name => "customers_ibfk_1"
      remove_foreign_key :customers, :name => "customers_ibfk_2"
      remove_foreign_key :customers, :name => "customers_ibfk_3"
    end

    change_table(:deliverables, :bulk => true) do |t|
      t.remove_foreign_key :name => "deliverables_ibfk_1"
      t.remove_foreign_key :name => "deliverables_ibfk_2"
    end

    change_table(:delivery_methods_orders, :bulk => true) do |t|
      t.remove_foreign_key :name => "delivery_methods_orders_ibfk_1"
      t.remove_foreign_key :name => "delivery_methods_orders_ibfk_2"
    end

    change_table(:ead_refs_master_files, :bulk => true) do |t|
      t.remove_foreign_key :name => "ead_refs_master_files_ibfk_1"
      t.remove_foreign_key :name => "ead_refs_master_files_ibfk_2"
    end

    change_table(:image_tech_meta, :bulk => true) do |t|
      t.remove_foreign_key :name => "image_tech_meta_ibfk_1"
    end

    change_table(:invoices, :bulk => true) do |t|
      t.remove_foreign_key :name => "invoices_ibfk_1"
    end

    change_table(:legacy_identifiers_master_files, :bulk => true) do |t|
      t.remove_foreign_key :name => "legacy_identifiers_master_files_ibfk_1"
      t.remove_foreign_key :name => "legacy_identifiers_master_files_ibfk_2"
    end

    change_table(:master_files, :bulk => true) do |t|
      t.remove_foreign_key :name => 'master_files_ibfk_3'
      t.remove_foreign_key :name => 'master_files_ibfk_2'
      t.remove_foreign_key :name => 'master_files_ibfk_1'
    end

    change_table(:orders, :bulk => true) do |t|
      t.remove_foreign_key :name => 'orders_ibfk_1'
      t.remove_foreign_key :name => 'orders_ibfk_2'
      t.remove_foreign_key :name => 'orders_ibfk_3'
    end

    change_table(:staff_members, :bulk => true) do |t|
      t.remove_foreign_key :name => "staff_members_ibfk_1"
    end

    change_table(:unit_import_sources, :bulk => true) do |t|
      t.remove_foreign_key :name => "unit_import_sources_ibfk_1"
    end

    change_table(:units, :bulk => true) do |t|
      t.remove_foreign_key :name => "units_ibfk_1"
      t.remove_foreign_key :name => "units_ibfk_2"
      t.remove_foreign_key :name => "units_ibfk_3"
      t.remove_foreign_key :name => "units_ibfk_4"
      t.remove_foreign_key :name => "units_ibfk_5"
      t.remove_foreign_key :name => "units_ibfk_6"
      t.remove_foreign_key :name => "units_ibfk_7"
      t.remove_foreign_key :name => "units_ibfk_8"
      t.remove_foreign_key :name => "units_ibfk_9"
    end

    drop_table :datastreams
    drop_table :deliverables_delivery_methods
   	drop_table :deliverables
    drop_table :delivery_methods_units
   	drop_table :image_specs
   	drop_table :tasks
    drop_table :text_tech_meta
    drop_table :vendor_batches
   	drop_table :vendors
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




    #TODO: Remove this after ms3uf changes Tracksys2 DB
    change_table(:components, :bulk => true) do |t|
      t.remove :seq_number
      t.remove :barcode
      t.remove :idno
    end

    create_table :containers do |t|
      t.string :barcode
      t.integer :container_type_id
      t.string :label
      t.integer :parent_container_id, :default => 0, :null => false
      t.string :sequence_no
    end

    add_index :containers, :parent_container_id

    create_table :components_containers do |t|
      t.integer :component_id
      t.integer :container_id
    end

    add_index :components_containers, :component_id
    add_index :components_containers, :container_id
    add_foreign_key :components_containers, :components
    add_foreign_key :components_containers, :containers

    create_table :bibls_components do |t|
      t.integer :bibl_id
      t.integer :component_id
    end

    add_index :bibls_components, :bibl_id
    add_index :bibls_components, :component_id
    add_foreign_key :bibls_components, :bibls
    add_foreign_key :bibls_components, :components

    create_table :container_types do |t|
      t.string :name
      t.string :description
    end

    add_index :container_types, :name, :unique => true
    add_foreign_key :containers, :container_types

    create_table :components_legacy_identifiers do |t|
      t.integer :component_id
      t.integer :legacy_identifier_id
    end

    add_index :components_legacy_identifiers, :component_id
    add_index :components_legacy_identifiers, :legacy_identifier_id

    add_foreign_key :components_legacy_identifiers, :components
    add_foreign_key :components_legacy_identifiers, :legacy_identifiers

  end
end
