class ConvertExternalSystemToModelReference < ActiveRecord::Migration[5.2]
  def up
     add_reference :metadata, :external_system, index: true
     add_reference :metadata, :supplemental_system, index: true

     as = ExternalSystem.find_by(name: "ArchivesSpace")
     apollo = ExternalSystem.find_by(name: "Apollo")

     puts "Convert external ArchivesSpace..."
     sql = "update metadata set external_system_id=#{as.id} where external_system='#{as.name}'"
     ExternalMetadata.connection.execute(sql)

     puts "Convert external Apollo..."
     sql = "update metadata set external_system_id=#{apollo.id} where external_system='#{apollo.name}'"
     ExternalMetadata.connection.execute(sql)

     puts "Convert supplemental ArchivesSpace..."
     sql = "update metadata set supplemental_system_id=#{as.id} where supplemental_system='#{as.name}'"
     ExternalMetadata.connection.execute(sql)

     puts "Convert supplemental Apollo..."
     sql = "update metadata set supplemental_system_id=#{apollo.id} where supplemental_system='#{apollo.name}'"
     ExternalMetadata.connection.execute(sql)

     remove_column :metadata, :external_system, :string
     remove_column :metadata, :supplemental_system, :string
  end

  def down
     as = ExternalSystem.find_by(name: "ArchivesSpace")
     apollo = ExternalSystem.find_by(name: "Apollo")

     add_column :metadata, :external_system, :string
     add_column :metadata, :supplemental_system, :string

     puts "Convert external ArchivesSpace..."
     sql = "update metadata set external_system='#{as.name}' where external_system_id='#{as.id}'"
     ExternalMetadata.connection.execute(sql)

     puts "Convert external Apollo..."
     sql = "update metadata set external_system='#{apollo.name}' where external_system_id='#{apollo.id}'"
     ExternalMetadata.connection.execute(sql)

     puts "Convert supplemental ArchivesSpace..."
     sql = "update metadata set supplemental_system='#{as.name}' where supplemental_system_id='#{as.id}'"
     ExternalMetadata.connection.execute(sql)

     puts "Convert supplemental Apollo..."
     sql = "update metadata set supplemental_system='#{apollo.name}' where supplemental_system_id='#{apollo.id}'"
     ExternalMetadata.connection.execute(sql)

     remove_reference :metadata, :external_system, index: true
     remove_reference :metadata, :supplemental_system, index: true
  end
end
