class CreateCollectionFacets < ActiveRecord::Migration
  def change
    create_table :collection_facets do |t|
      t.string :name
      t.timestamps null: false
    end
  end
end
