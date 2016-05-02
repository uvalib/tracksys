class DropUnusedComponentsColumns < ActiveRecord::Migration
   def up
      remove_column :components, :rels_ext
      remove_column :components, :rels_int
      remove_column :components, :dc
      remove_column :components, :solr
      remove_column :components, :legacy_ead
   end

   def down
      add_column :components, :rels_ext, :text
      add_column :components, :rels_int, :text
      add_column :components, :dc, :text
      add_column :components, :solr, :text
      add_column :components, :legacy_ead, :text
   end
end
