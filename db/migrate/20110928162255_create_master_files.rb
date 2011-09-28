class CreateMasterFiles < ActiveRecord::Migration
  def change
    create_table :master_files do |t|
      
      # External Relationships
      t.integer :availability_policy_id # Only for repository-bound objects.  Determines access policies for this digital object.  This value may be inherited from the object's parent (i.e. Unit)
      t.integer :component_id
      t.integer :ead_ref_id
      t.string :tech_meta_type # Used to distinguish what kind of MasterFile object this is (i.e. image, audio, video, etc...)
      t.integer :unit_id, :null => false, :default => 0  # required (zero will fail foreign key constraint)
      t.integer :use_right_id # Only for repository-bound objects.  What rights for reuse does patron have this object discovered through DL.  This value may be inherited from the object's parent (i.e. Unit)
      t.integer :automation_messages_count
      
      # General Master File Information
      t.string :description
      t.string :filename
      t.integer :filesize
      t.string :md5
      t.string :title

      # DL objects
      t.text :dc
      t.text :desc_metadata
      t.boolean :discoverability, :null => false, :default => 0
      t.boolean :locked_desc_metadata, :null => false, :default => 0
      t.string :pid
      t.text :rels_ext
      t.text :rels_int
      t.text :solr, :limit => 16777215
      t.text :transcription_text

      t.datetime :date_ingested_into_dl

      t.timestamps
    end
    
    add_index :master_files, :unit_id
    add_index :master_files, :component_id
    add_index :master_files, :ead_ref_id
    add_index :master_files, :use_right_id
    add_index :master_files, :availability_policy_id
    add_index :master_files, :tech_meta_type
    add_index :master_files, :filename
    add_index :master_files, :title
    add_index :master_files, :description, :length => 30
    add_index :master_files, :transcription_text, :length => 30
    add_index :master_files, :pid
    
  end
end