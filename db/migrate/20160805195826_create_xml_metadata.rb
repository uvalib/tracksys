class CreateXmlMetadata < ActiveRecord::Migration
  def up
    create_table :xml_metadata do |t|
      t.text :title
      t.text :creator_name
      t.string :schema
      t.text :content
      t.boolean :is_approved
      t.boolean :is_personal_item
      t.string :resource_type
      t.string :genre
      t.boolean :is_manuscript
      t.boolean :is_collection
      t.string :pid
      t.boolean :is_in_catalog
      t.string :exemplar
      t.boolean :discoverability
      t.datetime :date_dl_ingest
      t.datetime :date_dl_update
      t.integer :units_count
      t.string :collection_facet
      t.timestamps null: false
    end
    add_reference :xml_metadata, :indexing_scenario, index: true
    add_reference :xml_metadata, :availability_policy, index: true
    add_reference :xml_metadata, :use_right, index: true

    # add counter cache to all above tables
    add_column :indexing_scenarios, :xml_metadata_count, :integer, :default=>0
    add_column :availability_policies, :xml_metadata_count, :integer, :default=>0
    add_column :use_rights, :xml_metadata_count, :integer, :default=>0

  end

  def down
     drop_table :xml_metadata
     remove_column :indexing_scenarios, :xml_metadata_count
     remove_column :availability_policies, :xml_metadata_count
     remove_column :use_rights, :xml_metadata_count, :integer
  end
end
