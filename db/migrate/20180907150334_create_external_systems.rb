class CreateExternalSystems < ActiveRecord::Migration[5.2]
  def change
    create_table :external_systems do |t|
      t.string :name, index: true
      t.string :public_url
      t.string :api_url
    end

    # NOTE: By default the production URLs are added here. For reference, the dev URLs are:
    # STAFF: http://archives-test.lib.virginia.edu
    # PUBLIC: http://archives-test.lib.virginia.edu:8081
    # API: http://archives-test.lib.virginia.edu:8089
    #
    ExternalSystem.create([
      {name: "ArchivesSpace", public_url: "https://archives.lib.virginia.edu", api_url: "http://archivesspace01.lib.virginia.edu:8089"},
      {name: "Apollo", public_url: "https://apollo.lib.virginia.edu", api_url: "https://apollo.lib.virginia.edu/api"},
    ])
  end
end
