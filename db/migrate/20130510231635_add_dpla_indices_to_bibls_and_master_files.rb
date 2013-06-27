class AddDplaIndicesToBiblsAndMasterFiles < ActiveRecord::Migration
  def change
    change_table(:bibls, :bulk => true) do |t|
      t.index :dpla
    end

    change_table(:master_files, :bulk => true) do |t|
      t.index :dpla
    end
  end
end
