class AddPublicationPlaceToBibl < ActiveRecord::Migration
  def change
    add_column :bibls, :publication_place, :string
  end
end
