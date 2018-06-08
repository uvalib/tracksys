class AddNotesToLocation < ActiveRecord::Migration[5.2]
  def change
     add_column :locations, :notes, :text
  end
end
