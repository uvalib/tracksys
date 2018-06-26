namespace :apollo do
   desc "Add an OMW2 external metadata record"
   task :add_omw2 => :environment do
      uid = ENV['unit']
      vol = ENV['vol']
      num = ENV['num']
      pid = ENV['pid']
      apollo = ENV['apollo']
      abort("unit, vol, num, apollo required") if vol.nil? || num.nil? || apollo.nil? || uid.nil?

      unit = Unit.find(uid)
      title = "Our mountain work in the Diocese of Virginia: Our Mountain Work, Vol. #{vol}, no. #{num}"

      puts("Add ext metadata #{title} from #{unit.to_json}")

      md = ExternalMetadata.create(parent_metadata_id: 16104,
         pid: pid, title: title, is_approved: true, use_right_id: 1,ocr_hint_id: 1,discoverability: 0,
         availability_policy_id: 1, external_system: "Apollo", external_uri: "/api/items/#{apollo}")
      unit.update(metadata: md)
      unit.master_files.update_all(metadata_id: md.id, component_id: nil)
   end

   desc "Fix apollo link"
   task :fix  => :environment do
      id = ENV['id']
      abort("ID is required") if id.nil?
      offsetStr = ENV['offset']
      abort("offset is required") if offsetStr.nil?
      offset = offsetStr.to_i
      sm = SirsiMetadata.find(id)
      puts "Updating ext_uri id by #{offset} for #{sm.title} children..."
      ExternalMetadata.where(external_system: "Apollo", parent_metadata_id: id).find_each do |am|
         puts "#{am.id} = #{am.title}:#{am.external_uri}"
         uri = am.external_uri
         num = uri.split("-")[1].gsub(/an/,"").to_i
         newNum = "an#{num+offset}"
         newUri = "#{uri.split("-")[0]}-#{newNum}"
         am.update(external_uri: newUri)
      end
   end

   desc "Convert an entire componet-based serial to Apollo ExternalMetadata"
   task :convert  => :environment do
      pid = ENV['pid']
      component = Component.find_by(pid: pid)
      abort("PID not found") if component.blank?

      # Walk component tree, generate apollo ext metadata and delete unused components
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
         if component.master_files.first.blank?
            puts "#{pad}WARNING: #{component.id}:#{component.title} has no master files. Skip."
            component.destroy
            return
         end
         orig_metadata = component.master_files.first.metadata
         unit = component.master_files.first.unit
         apollo_pid = RestClient.get "#{Settings.apollo_url}/api/external/#{component.pid}"
         abort("Unable to find related Apollo item!") if apollo_pid.blank?

         # Update the top-level sirsi metadata representing this item to have
         # a reference to apollo for supplemental metadata
         if orig_metadata.supplemental_system.blank?
            orig_metadata.update(supplemental_system: "Apollo", supplemental_uri:"/collections/#{apollo_pid}")
         end

         md = ExternalMetadata.create(parent_metadata_id: orig_metadata.id,
            pid: component.pid, title: "#{orig_metadata.title}: #{component.title}",
            is_approved: true, use_right: orig_metadata.use_right,
            ocr_hint_id: orig_metadata.ocr_hint_id,
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

      apollo_pid = RestClient.get "#{Settings.apollo_url}/api/external/#{pid}"

      md = ExternalMetadata.create(parent_metadata_id: orig_metadata.id,
         pid: pid, title: "#{orig_metadata.title}: #{component.title}",
         is_approved: true, use_right: orig_metadata.use_right, ocr_hint_id: 1,
         discoverability: 1, availability_policy_id: 1,
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

   # Read the legacy CSV files and parse them into a hierarchical XML document of the
   # format Apollo can ingest.
   # Format:  Collection / year (YYYY) / month (name) / digital_content
   #
   desc "Convert WSLS into apollo XML and controlled vocabulary"
   task :convert_wsls  => :environment do
      wsls_csv = File.join(Rails.root, "data", "wsls.csv")
      dur_csv = File.join(Rails.root, "data", "wsls-durations.csv")
      desc_file  = File.join(Rails.root, "data", "wsls-desc.txt")
      title = "WSLS-TV (Roanoke, VA) News Film Collection, 1951 to 1971"
      year_desc_template = "Video clips and corresponding anchor scripts from #YEAR."
      xml_doc = Nokogiri::XML::Document.new

      puts "Read durations into hash..."


      puts
      puts "DONE; writing file..."
      File.write("wsls.xml", xml_doc.to_xml)
   end

   desc "Parse out WSLS controlled vocabulary into Apollo ingest files"
   task :wsls_vocab  => :environment do
      topics = {}
      places = {}
      colors = []
      tags = []
      s_cnt = 0
      wsls_csv = File.join(Rails.root, "data", "wsls.csv")
      CSV.foreach(wsls_csv, headers: true) do |row|
         # O (14) and P (15) are topic val and URI
         topic = row[14]
         if !topic.blank?
            if !topics.has_key? topic
               topics[topic] = row[15]
            end
         end

         # Q (15) and R (16) are topic/URI too
         topic = row[16]
         if !topic.blank?
            if !topics.has_key? topic
               topics[topic] = row[17]
            end
         end

         # S is a topic, but has no URI? Throw it away?
         topic = row[18]
         if !topic.blank?
            if !topics.has_key? topic
               puts "WARN: Controlled vocab for topic [#{topic}] with no URI"
               topics[topic] = ""
            end
         end

         # T (19) and U (20) are place val and URI
         place = row[19]
         if !place.blank?
            if !places.has_key? place
               places[place] = row[20]
            end
         end

         [21,22].each do |col_idx|
            val = row[col_idx]
            next if val.blank?
            if !topics.has_key? val
               puts "WARN: Controlled vocab for place [#{val}] with no URI"
               places[val] = ""
            end
         end

         # 34 = wslsColor
         val = row[34]
         if !val.blank? && !colors.include?(val)
            colors << val
         end

         # 35 - wslsTag
         val = row[35]
         if !val.blank? && !tags.include?(val)
            tags << val
         end
      end

      puts "Create SQL for new node_types..."
      out = File.open("wsls_node_types.sql", "w")
      out.write("insert into node_types (id,name,controlled_vocab) values\n")
      out.write("  (15,'wslsTopic',1), (16,'wslsPlace', 1), (17,'wslsColor', 1), (18,'wslsTag', 1);\n")
      out.close

      puts "Create SQL insert for topics..."
      out = File.open("wsls_topics.sql", "w")
      out.write("insert into controlled_values (node_type_id,value,value_uri) values\n  ")
      topics.sort.each_with_index do |ele, idx|
         out.write(",\n  ") if idx > 0
         out.write("(15,'#{ele[0]}','#{ele[1]}')")
      end
      out.write(";")
      out.close

      puts "Create SQL insert for places..."
      out = File.open("wsls_places.sql", "w")
      out.write("insert into controlled_values (node_type_id,value,value_uri) values\n  ")
      places.sort.each_with_index do |ele, idx|
         out.write(",\n  ") if idx > 0
         out.write("(16,'#{ele[0]}','#{ele[1]}')")
      end
      out.write(";")
      out.close

      puts "Create SQL insert for wslsColor..."
      out = File.open("wsls_color.sql", "w")
      out.write("insert into controlled_values (node_type_id,value) values\n  ")
      colors.sort.each_with_index do |ele, idx|
         out.write(",\n  ") if idx > 0
         out.write("(17,'#{ele}')")
      end
      out.write(";")
      out.close

      puts "Create SQL insert for wslsTag..."
      out = File.open("wsls_tag.sql", "w")
      out.write("insert into controlled_values (node_type_id,value) values\n  ")
      tags.sort.each_with_index do |ele, idx|
         out.write(",\n  ") if idx > 0
         out.write("(18,'#{ele}')")
      end
      out.write(";")
      out.close
   end
end
