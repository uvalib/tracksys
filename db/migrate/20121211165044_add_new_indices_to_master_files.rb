class AddNewIndicesToMasterFiles < ActiveRecord::Migration
  def change
    change_table(:master_files, :bulk => true) do |t|
      t.index :date_dl_ingest
      t.index :date_dl_update
    end
  end
end
