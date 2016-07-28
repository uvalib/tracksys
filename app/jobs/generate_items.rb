class GenerateItems < BaseJob

   # Generate items ( sets of master files in page order )
   # A unit will always have at least one item. If a unit contains
   # components, each leaf-component (component that contains master files)
   # will also be an item. Master files with desc_metadata will get their
   # own item
   #
   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      unit =  message[:unit]

      curr_component_id = 0
      curr_item = nil
      page_one_found = false

      unit.master_files.each do |mf|
         next if !mf.item.nil? # if item is somehow already tied to the MF, skip

         # If MF has desc_metadata, it always goes in its own item
         if !mf.desc_metadata.blank?
            page_one_found = false
            curr_item = nil
            curr_component_id = 0
            puts "Creating new item for MF #{mf.pid}:#{mf.title} with desc_metadata"
            mf.item = Item.create(unit_id: unit.id)
            mf.save!
            next
         end

         # A new component starts a new item.
         if curr_component_id == 0 && !mf.component.nil?
            puts "Leaf-level component #{mf.component.pid} found; creating item"
            page_one_found = false
            curr_component_id = mf.component.id
            curr_item = Item.create(unit_id: unit.id)
         end

         # get page num from title. Return 0 if any non-numeric data present.
         # Only care if page is 1 as this is where item may change. If title
         # fails, fall back to desctiption as some store this info there
         page_num = get_page_number(mf.title)
         page_num = get_page_number(mf.description) if page_num == 0
         if page_num == 1
            if page_one_found == false
               page_one_found = true
            else
               # multiple page 1 found; create a new component
               puts "Page cycle found; creating item"
               curr_item = Item.create(unit_id: unit.id)
            end
         end

         # at this point, if there still is no item, create one
         if curr_item.nil?
            puts "Creating item"
            curr_item = Item.create(unit_id: unit.id)
         end

         # Add page to whatever item is current
         mf.item = curr_item
         mf.save!
      end
   end

   def get_page_number( text )
      return 0 if text.blank?
      return 0 if text.strip.match(/\A[-+]?[0-9]*\.?[0-9]+\Z/).nil?
      return text.to_i
   end
end
