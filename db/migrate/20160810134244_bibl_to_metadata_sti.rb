class BiblToMetadataSti < ActiveRecord::Migration
  def change
     # Rename BIBLS to METADATA
     rename_table :bibls, :metadata
     rename_table :bibls_components, :sirsi_metadata_components
     rename_table :bibls_legacy_identifiers, :sirsi_metadata_legacy_identifiers
     rename_column :sirsi_metadata_legacy_identifiers, :bibl_id, :sirsi_metadata_id
     rename_column :sirsi_metadata_components, :bibl_id, :sirsi_metadata_id

     # Update related table column names
     rename_column :availability_policies, :bibls_count, :metadata_count
     rename_column :indexing_scenarios, :bibls_count, :metadata_count
     rename_column :use_rights, :bibls_count, :metadata_count

     # Fix unit refernce
     rename_column :units, :bibl_id, :metadata_id

     # Retire columns that are pulled from metadata source on the fly
     remove_column :metadata, :description, :string
     remove_column :metadata, :series_title, :string
     remove_column :metadata, :creator_name_type, :string
     remove_column :metadata, :title_control, :string
     remove_column :metadata, :copy, :string
     remove_column :metadata, :volume, :string
     remove_column :metadata, :location, :string
     remove_column :metadata, :year, :string
     remove_column :metadata, :year_type, :string
     remove_column :metadata, :date_external_update, :string
     remove_column :metadata, :issue, :string
     remove_column :metadata, :citation, :text
     remove_column :metadata, :cataloging_source, :string
     remove_column :metadata, :publication_place, :string

     # Add the STI type column
     add_column :metadata, :type, :string, :default=>"SirsiMetadata"  # XML and ArchivesSpace are other options

     # Add a few columns to manage differences for specific types
     # XML Metadata
     add_column :metadata, :xml_schema, :string

     # External metadata attributes. Stored as a hash.
     # USed to provide conext for finding metdata from external source
     add_column :metadata, :external_attributes, :text

  end
end
