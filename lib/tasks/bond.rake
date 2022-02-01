namespace :bond do
   desc "Create julian bond agency"
   task :create_agency  => :environment do
      a = Agency.find_by(name: "Julian Bond Papers")
      if a.nil?
         puts "Creating agency for 'Julian Bond Papers'"
         Agency.create(name: "Julian Bond Papers", description: "Julian Bond papers digitizaed by Center for Digital Editing",
            ancestry: "51", names_depth_cache: "Internal Administrative Unit")
      end
   end

   desc "Create location records for folders in boxes 4 and 5"
   task :create_locations  => :environment do
      puts "Looking up metadata records for box 4 and box 5..."
      box4 = SirsiMetadata.find_by(barcode: "X030098648")   # BOX 4 metadata
      box5 = SirsiMetadata.find_by(barcode: "X030098649")   # BOX 5 metadata
      if box4.nil? || box5.nil?
         abort "Box4 and/or Box5 metadata record missing. Please create them now."
      end
      puts "BOX 4: #{box4.id}"
      puts "BOX 5: #{box5.id}"

      puts "Lookup box container type..."
      box_type = ContainerType.find_by(name: "Box")

      puts "Parse CSV for locations..."
      csv_file = File.join(Rails.root,  "data", "BondPapers-Series1-box1-5.csv")
      cnt = 0
      CSV.parse( File.read(csv_file), headers: true ).each do |row|
         # col 1: title, col 8: BOX/FOLDER, col 9: num pages, col 10: filenames with | sep
         # Box format: "Box # Folder #"
         puts "Create location #{row[8]}"
         bits = row[8].split(" ")
         box_num = bits[1]
         folder_num = bits[3]
         md_rec = box5
         md_rec = box4 if box_num == "4"

         exist = Location.where("metadata_id=? and container_type_id=? and container_id=? and folder_id=?",
            md_rec.id,  box_type.id, box_num, folder_num).first
         if exist.nil?
            Location.create!(metadata_id: md_rec.id, container_type_id: box_type.id, container_id: box_num, folder_id: folder_num)
            cnt +=1
         else
            puts "Location #{row[8]} already exists"
         end
      end
      puts "DONE. #{cnt} locations created"
   end
end
