class Location < ApplicationRecord
   belongs_to :container_type
   has_many :master_file_locations
   has_many :master_files, through: :master_file_locations

   validates :folder_id, :container_type, :container_id, presence: true


   # Given the unit base directory (ex: /digiserv-production/finalization/20_in_process/000033333)
   # and the full path to a masterfile, determine if location data is encoded in the path
   # and return location metadata. Return nil if there is no data in the path.
   #
   def self.find_or_create_from_path(unit_base_dir, full_path_to_mf)
      subdir_str = File.dirname(full_path_to_mf)[unit_base_dir.length+1..-1]
      return nil if subdir_str.blank?

      # Naming convention: [box|oversize|tray].{boxname}/{foldername}
      bits = subdir_str.split("/")
      folder = bits[1]
      box_info = bits[0].split(".")
      type = box_info[0]
      box_id = box_info[1]
      ct = ContainerType.where("name like ?", type).first

      location = Location.find_by(container_type_id: ct.id, container_id: box_id, folder_id: folder)
      if location.nil?
         # See if there is a notes.txt file present in the base dir. Add the contents
         # as a note if present
         notes_file = File.join(unit_base_dir, "notes.txt")
         notes = nil
         if File.exist? notes_file
            file = File.open(notes_file, "rb")
            notes = file.read
            file.close
         end
         location = Location.create(container_type_id: ct.id, container_id: box_id, folder_id: folder, notes: notes)
      end
      return location
   end
end
