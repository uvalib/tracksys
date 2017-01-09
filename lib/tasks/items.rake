namespace :items do
   desc "Clean up all items"
   task :purge => :environment do
      puts "Removing all items..."
      MasterFile.connection.execute("update master_files set item_id=null")
      Item.connection.execute("truncate items")
   end

   desc "Create items from leaf-level components"
   task :from_components  => :environment do

      item = nil
      curr_component_id = nil
      pg_1_found = false

      MasterFile.where("component_id is not null").where("item_id is null").order(component_id: :asc).each do |mf|

         # when a new component is found, create a new item for it
         if mf.component_id != curr_component_id
            puts "Creating item for component #{mf.component.title}"
            curr_component_id = mf.component_id
            pg_1_found = false
            item = Item.create(unit_id: mf.unit_id, metadata_id: mf.metadata.id)
         end

         # get page num from title. Return 0 if any non-numeric data present
         # only care of page is 1 as this is where item may change. If title
         # fails, fall back to desctiption as some store this info there
         page_num = get_page_number(mf.title)
         page_num = get_page_number(mf.description) if page_num == 0
         if page_num == 1
            if pg_1_found == false
               puts "   Found page 1 in #{mf.component.title}"
               pg_1_found = true
            else
               # multiple page 1 found; create a new component
               puts "   Page cycle found; creating item"
               item = Item.create(unit_id: mf.unit_id, metadata_id: mf.metadata.id)
            end
         end

         # Add page to whatever item is current
         mf.item = item
         mf.save!
      end
   end

   def get_page_number( text )
      return 0 if text.blank?
      return 0 if text.strip.match(/\A[-+]?[0-9]*\.?[0-9]+\Z/).nil?
      return text.to_i
   end

   desc "Create items from all units"
   task :from_units  => :environment do
      Unit.where(unit_status: "approved").where(intended_use_id: 110).each do |u|
         next if u.master_files.first.nil?               # no master files; skip!!
         next if !u.master_files.first.component.nil?    # components handled by other task

         page_one_found = false
         item = nil

         # Check for page cycles in this unts master_files
         u.master_files.each do |mf|
            next if !mf.item.nil? # if item already set, don't create new!

            # If MF has desc_metadata, it always goes in its own item
            if mf.metadata.type == "XmlMetadata" && mf.metadata.master_files.size == 1 && mf.metadata.master_files.first == mf
               page_one_found = false
               item = nil
               puts "Creating new item for MF #{mf.pid}:#{mf.title} with desc_metadata"
               mf.item = Item.create(unit_id: mf.unit_id, metadata_id: mf.metadata.id)
               mf.save!
               next
            end

            # get page num from title. Return 0 if any non-numeric data present
            # only care of page is 1 as this is where item may change. If title
            # fails, fall back to desctiption as some store this info there
            page_num = get_page_number(mf.title)
            page_num = get_page_number(mf.description) if page_num == 0
            if page_num == 1
               if page_one_found == false
                  page_one_found = true
               else
                  # multiple page 1 found; create a new component
                  puts "   Page cycle found; creating item"
                  item = Item.create(unit_id: mf.unit_id, metadata_id: mf.metadata.id)
               end
            end

            # at this point, if there still is no item, create one
            if item.nil?
               puts "Creating item for unit #{mf.unit_id}"
               item = Item.create(unit_id: mf.unit_id, metadata_id: mf.metadata.id)
            end

            # Add page to whatever item is current
            mf.item = item
            mf.save!
         end
      end
   end

   desc "Create item(s) from a unit unit"
   task :from_units  => :environment do
      uid = ENV[:id]
      unit = Unit.find(uid)
      abort("Unit is part of a component") if !u.master_files.first.component.nil?

      page_one_found = false
      item = nil

      # Check for page cycles in this unts master_files
      u.master_files.each do |mf|
         next if !mf.item.nil? # if item already set, don't create new!

         # If MF has desc_metadata, it always goes in its own item
         if mf.metadata.type == "XmlMetadata" && mf.metadata.master_files.size == 1 && mf.metadata.master_files.first == mf
            page_one_found = false
            item = nil
            puts "Creating new item for MF #{mf.pid}:#{mf.title} with desc_metadata"
            mf.item = Item.create(unit_id: mf.unit_id, metadata_id: mf.metadata.id)
            mf.save!
            next
         end

         # get page num from title. Return 0 if any non-numeric data present
         # only care of page is 1 as this is where item may change. If title
         # fails, fall back to desctiption as some store this info there
         page_num = get_page_number(mf.title)
         page_num = get_page_number(mf.description) if page_num == 0
         if page_num == 1
            if page_one_found == false
               page_one_found = true
            else
               # multiple page 1 found; create a new component
               puts "   Page cycle found; creating item"
               item = Item.create(unit_id: mf.unit_id, metadata_id: mf.metadata.id)
            end
         end

         # at this point, if there still is no item, create one
         if item.nil?
            puts "Creating item for unit #{mf.unit_id}"
            item = Item.create(unit_id: mf.unit_id, metadata_id: mf.metadata.id)
         end

         # Add page to whatever item is current
         mf.item = item
         mf.save!
      end
   end
end
