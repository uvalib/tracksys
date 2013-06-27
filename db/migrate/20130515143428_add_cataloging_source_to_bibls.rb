class AddCatalogingSourceToBibls < ActiveRecord::Migration
  def change
    add_column :bibls, :cataloging_source, :string
    add_index :bibls, :cataloging_source
  end
end
