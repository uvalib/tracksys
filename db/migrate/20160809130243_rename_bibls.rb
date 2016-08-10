class RenameBibls < ActiveRecord::Migration
  def change
     rename_table :bibls, :sirsi_metadata
     rename_table :bibls_components, :sirsi_metadata_components
     rename_table :bibls_legacy_identifiers, :sirsi_metadata_legacy_identifiers
     rename_column :sirsi_metadata_legacy_identifiers, :bibl_id, :sirsi_metadata_id
     rename_column :sirsi_metadata_components, :bibl_id, :sirsi_metadata_id

     rename_column :availability_policies, :bibls_count, :sirsi_metadata_count
     rename_column :indexing_scenarios, :bibls_count, :sirsi_metadata_count
     rename_column :use_rights, :bibls_count, :sirsi_metadata_count

     remove_column :sirsi_metadata, :description, :string
     remove_column :sirsi_metadata, :series_title, :string
     remove_column :sirsi_metadata, :creator_name_type, :string
     remove_column :sirsi_metadata, :title_control, :string
     remove_column :sirsi_metadata, :copy, :string
     remove_column :sirsi_metadata, :volume, :string
     remove_column :sirsi_metadata, :location, :string
     remove_column :sirsi_metadata, :year, :string
     remove_column :sirsi_metadata, :year_type, :string
     remove_column :sirsi_metadata, :date_external_update, :string
     remove_column :sirsi_metadata, :issue, :string
     remove_column :sirsi_metadata, :citation, :text
     remove_column :sirsi_metadata, :cataloging_source, :string
     remove_column :sirsi_metadata, :publication_place, :string
  end
end
