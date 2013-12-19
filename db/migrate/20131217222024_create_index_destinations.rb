class CreateIndexDestinations < ActiveRecord::Migration
  def change
    create_table :index_destinations do |t|
      t.string :nickname
      t.string :hostname, default: 'localhost'
      t.string :port, default: '8080'
      t.string :protocol, default: 'http'
      t.string :context, default: 'solr'
      t.timestamps
    end
  end
end
