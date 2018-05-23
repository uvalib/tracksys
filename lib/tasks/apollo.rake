namespace :apollo do
   desc "Convert an entire componet-based serial to Apollo ExternalMetadata"
   task :convert  => :environment do
      pid = ENV['pid']
      component = Component.find_by(pid: pid)
      abort("PID not found") if component.blank?

      # FIRST, set up apollo as supplemental metadata for root
      apollo_pid = RestClient.get "#{Settings.apollo_url}/api/external/#{component.pid}"
      abort("Unable to find related Apollo item!") if apollo_pid.blank?
      orig_metadata = component.master_files.first.metadata
      orig_metadata.update(supplemental_system: "Apollo", supplemental_uri:"/collections/#{apollo_pid}")

      # Now walk tree, generate apollo ext metadata and delete unused components
      walk_tree(component, 0)
   end

   def walk_tree(component, depth)
      pad = "  "*depth
      if component.children.count > 0
         # This component is a container for other components.
         # Descend through each of them....
         puts "#{pad}START #{component.title}"
         component.children.each do |child|
            walk_tree( child, depth+1 )
         end

         # This container has had all of its children processed.
         # It is no longer needed; delete it
         puts "#{pad}END #{component.title}"
         component.destroy
      else
         # This is a leaf of the component tree. It holds all of the
         # master files and is the point of conversion to Apollo
         puts "#{pad}LEAF #{component.title}; Convert to ExternalMetadata..."
         orig_metadata = component.master_files.first.metadata
         unit = component.master_files.first.unit
         apollo_pid = RestClient.get "#{Settings.apollo_url}/api/legacy/lookup/#{component.pid}"
         abort("Unable to find related Apollo item!") if apollo_pid.blank?

         md = ExternalMetadata.create(parent_metadata_id: orig_metadata.id,
            pid: component.pid, title: "#{orig_metadata.title}: #{component.title}",
            is_approved: true, use_right: orig_metadata.use_right,
            ocr_hint_id: orig_metadata.ocr_hint_id,
            exemplar: component.master_files.first.filename,
            discoverability: orig_metadata.discoverability,
            availability_policy_id: orig_metadata.availability_policy_id,
            external_system: "Apollo", external_uri: "/api/items/#{apollo_pid}")
         unit.update(metadata: md)
         unit.master_files.update_all(metadata_id: md.id, component_id: nil)
         component.destroy
         puts "#{pad}Converted"
      end
   end

   desc "Convert componet-based serial to Apollo ExternalMetadata"
   task :convert_one  => :environment do
      pid = ENV['pid']
      abort("param pid (component PID) is required") if pid.blank?
      component = Component.find_by(pid: pid)
      abort("PID not found") if component.blank?
      orig_metadata = component.master_files.first.metadata
      unit = component.master_files.first.unit

      apollo_pid = RestClient.get "#{Settings.apollo_url}/api/legacy/lookup/#{pid}"

      md = ExternalMetadata.create(parent_metadata_id: orig_metadata.id,
         pid: pid, title: "#{orig_metadata.title}: #{component.title}",
         is_approved: true, use_right: orig_metadata.use_right, ocr_hint_id: 1,
         exemplar: component.master_files.first.filename, discoverability: 1,
         availability_policy_id: 1,
         external_system: "Apollo", external_uri: "/api/items/#{apollo_pid}")
      unit.update(metadata: md)
      unit.master_files.update_all(metadata_id: md.id, component_id: nil)
      component.destroy
   end

   desc "dump Daily Progress as XML"
   task :dp  => :environment do
      # Structure: collection, year, month, issue (day)
      root_component = Component.find(497769)
      doc = Nokogiri::XML::Document.new

      puts "Generating daily progress XML..."
      struct = ["collection","year","month","issue"]
      traverse(struct, doc, root_component, 0, doc)
      puts
      puts "DONE; writing file..."
      File.write("daily_progress.xml", doc.to_xml)
   end

   desc "dump our mountain work as XML"
   task :omw  => :environment do
      component = Component.find(511278)
      doc = Nokogiri::XML::Document.new

      struct = ["collection","volume","issue"]
      traverse(struct, doc, component, 0, doc)

      puts doc.to_xml
   end

   desc "dump our mountain work in diocese as XML"
   task :omw2  => :environment do
      component = Component.find(510923)
      doc = Nokogiri::XML::Document.new

      struct = ["collection","volume","issue"]
      traverse(struct, doc, component, 0, doc)

      puts doc.to_xml
   end

   def add_dl_info(component, doc)
      metadata = component.metadata.first
      node = Nokogiri::XML::Node.new "useRights", doc
      node.content = metadata.use_right.name
      doc.add_child(node)

      node = Nokogiri::XML::Node.new "barcode", doc
      node.content = metadata.barcode
      doc.add_child(node)

      node = Nokogiri::XML::Node.new "catalogKey", doc
      node.content = metadata.catalog_key
      doc.add_child(node)
   end

   def traverse(struct, xml_doc, curr_component, depth, curr_node)
      # Create node and add title + compoentPID (needed for virgo links)
      child_node = Nokogiri::XML::Node.new struct[depth], xml_doc
      curr_node.add_child(child_node)
      title = Nokogiri::XML::Node.new "title", xml_doc
      title.content = curr_component.title
      child_node.add_child title

      pid_obj = Nokogiri::XML::Node.new "externalPID", xml_doc
      pid_obj.content = curr_component.pid
      child_node.add_child(pid_obj)

      if depth == 0
         add_dl_info(curr_component, child_node)
      end

      # If there are children, traverse each
      if curr_component.children.count > 0
         depth += 1
         if struct[depth] == "year"
            children = curr_component.children.order(title: :asc)
         else
            children = curr_component.children
         end
         children.each do |child|
            traverse( struct, xml_doc, child, depth, child_node )
         end
      else
         # Check for reel info in content_desc
         if curr_component.content_desc.downcase.include? "reel"
            obj = Nokogiri::XML::Node.new "reel", xml_doc
            obj.content = curr_component.content_desc.split("reel").last.strip
            child_node.add_child(obj)
         end

         # this is a leaf; see if there is a representation
         dov = Settings.doviewer_url
         url = "#{dov}/images/#{curr_component.pid}"
         oembed = "#{dov}/oembed?url=#{CGI.escape(url)}"

         # add digitalObject node with oembed URL
         dobj = Nokogiri::XML::Node.new "digitalObject", xml_doc
         dobj.content = oembed
         child_node.add_child(dobj)
      end

   end
end
