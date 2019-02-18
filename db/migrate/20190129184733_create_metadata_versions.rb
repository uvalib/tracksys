class CreateMetadataVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :metadata_versions do |t|
      t.references :metadata, index: true, null: false
      t.references :staff_member, index: true, null: false
      t.text :desc_metadata
      t.string :version_tag, index: true, null: false
      t.timestamp :created_at, default: -> { 'CURRENT_TIMESTAMP' }
    end
  end
end
