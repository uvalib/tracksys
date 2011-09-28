class CreateBibls < ActiveRecord::Migration
  def change
    create_table :bibls do |t|
  
      # External References
      t.integer :availability_policy_id # Only for repository-bound objects
      t.integer :parent_bibl_id, :null => false, :default => 0, :references => nil
      
      # General information (i.e. fields never derived from outside source)
      t.datetime :date_external_update # If Bibl record created/updated from outside source
      t.string :description
      t.boolean :is_approved, :null => false, :default => 0  # boolean values should be 0 or 1 (disallow NULL)
      t.boolean :is_collection, :null => false, :default => 0
      t.boolean :is_in_catalog, :null => false, :default => 0
      t.boolean :is_manuscript, :null => false, :default => 0
      t.boolean :is_personal_item, :null => false, :default => 0
      t.integer :automation_messages_count, :default => 0
      t.integer :orders_count, :default => 0
      t.integer :units_count, :default => 0

          
      # Catalog information, pulled from Blacklight/Solr, if available
      t.string :barcode
      t.string :call_number
      t.string :catalog_id, :references => nil  # skip automatic creation of foreign key constraint based on column name ending with "_id" (foreign_key_migrations plugin)
      t.text :citation
      t.integer :copy
      t.string :creator_name
      t.string :creator_name_type
      t.string :genre
      t.string :issue # Not pulled from Blacklight; used to provide unique bibliographic information for journals
      t.string :location
      t.string :resource_type
      t.string :series_title
      t.string :title
      t.string :title_control
      t.string :volume # Not pulled from Blacklight; used to provide unique bibliographic information for journals
      t.string :year
      t.string :year_type
      
      # DL Objects Only
      t.text :dc
      t.text :desc_metadata
      t.boolean :discoverability, :null => false, :default => 1 # The defaul for Bibl objects is that they are discoverable
      t.string :exemplar
      t.string :pid # All Bibl objects get PIDs; only used if Bibl object is ingested into repository
      t.text :rels_ext
      t.text :rels_int
      t.text :solr, :limit => 16777215
      t.datetime :date_ingested_into_dl
          
      t.timestamps
    end
    
    add_index :bibls, :barcode
    add_index :bibls, :call_number
    add_index :bibls, :catalog_id
    add_index :bibls, :pid
    add_index :bibls, :title
    add_index :bibls, :availability_policy_id
    add_index :bibls, :parent_bibl_id
    
  end
end