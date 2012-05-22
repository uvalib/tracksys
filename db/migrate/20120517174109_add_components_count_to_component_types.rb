class AddComponentsCountToComponentTypes < ActiveRecord::Migration
  def change
    add_column :component_types, :components_count, :integer

  end
end
