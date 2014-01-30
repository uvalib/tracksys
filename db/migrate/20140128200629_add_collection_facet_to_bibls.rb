class AddCollectionFacetToBibls < ActiveRecord::Migration
  def change
    add_column :bibls, :collection_facet, :string
  end
end
