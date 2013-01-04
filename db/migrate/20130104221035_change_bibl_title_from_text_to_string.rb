class ChangeBiblTitleFromTextToString < ActiveRecord::Migration
  def change
    remove_index :bibls, :title
    change_column :bibls, :title, :text
 end
end
