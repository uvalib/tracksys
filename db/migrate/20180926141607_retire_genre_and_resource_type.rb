class RetireGenreAndResourceType < ActiveRecord::Migration[5.2]
  def up
     puts "Back up existing genre settings..."
     q = "select m.id, m.pid, g.name, r.name from metadata m"
     q << " left outer join genres g on g.id = m.genre_id left outer join resource_types r on r.id = m.resource_type_id"
     q << " where genre_id is not null or resource_type_id is not null"
     out = File.join(Rails.root, "data", "backups", "metadata_genre_resource.csv")
     cnt = 0
     csv = File.open(out, "w")
     csv.puts "metadata_id, metadata_pid, genre, resource_type"
     Metadata.connection.query(q).each do |r|
        csv.puts r.join(",")
        if cnt % 100 == 0
           print "."
        end
     end
     csv.close
     puts ""

     puts "Drop genre and resource type metadata column..."
     remove_reference :metadata, :genre, index: true
     remove_reference :metadata, :resource_type, index: true

     puts "Drop genre and resource type tables..."
     drop_table :genres
     drop_table :resource_types

     puts "DONE"
  end

  def down
     puts "This migration cann be rolled back"
  end
end
