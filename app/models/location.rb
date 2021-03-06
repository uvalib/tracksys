# == Schema Information
#
# Table name: locations
#
#  id                :bigint(8)        not null, primary key
#  container_type_id :bigint(8)
#  container_id      :string(255)      not null
#  folder_id         :string(255)
#  notes             :text(65535)
#  metadata_id       :bigint(8)
#

class Location < ApplicationRecord
   belongs_to :container_type
   belongs_to :metadata, optional: true
   has_and_belongs_to_many :master_files, join_table: "master_file_locations"

   validates :container_type, :container_id, presence: true


   # Given the container type and the directory structure, create or find a location
   # NOTE: the subdir_str does not have a leading or trailing /
   # NOTE: a location is uniquely identified by call number (metadsta record), container type, container ID and folder ID
   #
   def self.find_or_create(metadata, container_type, base_dir, subdir_str)
      return nil if subdir_str.blank?

      bits = subdir_str.split("/")
      location = Location.find_by(metadata_id: metadata.id, container_type_id: container_type.id,
         container_id: bits[0], folder_id: bits[1])
      if location.nil?
         # See if there is a notes.txt file present in the base dir. Add the contents
         # as a note if present
         notes_file = File.join(base_dir, "notes.txt")
         notes = nil
         if File.exist? notes_file
            file = File.open(notes_file, "rb")
            notes = file.read
            file.close
         end
         location = Location.create(metadata_id: metadata.id, container_type_id: container_type.id,
            container_id: bits[0], folder_id: bits[1], notes: notes)
      end
      return location
   end

   # Get the unique ids of all units that have master files from this location
   def units
      q = "select distinct unit_id from master_files m inner join master_file_locations l on l.master_file_id=m.id"
      q << " where location_id = #{id}"
      return Location.connection.query(q).flatten
   end
end
