class DropUnusedBiblsColumns < ActiveRecord::Migration
   def up
      remove_column :bibls, :rels_ext
      remove_column :bibls, :rels_int
      remove_column :bibls, :dc
      remove_column :bibls, :solr
   end

   def down
      add_column :bibls, :rels_ext, :text
      add_column :bibls, :rels_int, :text
      add_column :bibls, :dc, :text
      add_column :bibls, :solr, :text
   end
end
