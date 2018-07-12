namespace :apollo do
   desc "Convert digitalObject value to remove path to doviewer"
   task :convert_doviewer_value => :environment do
      hp = ENV['APOLLO_DB_HOST']
      host = hp.split(":")[0]
      port = hp.split(":")[1]
      conn = ActiveRecord::Base.establish_connection(
           :adapter  => "mysql2",
           :database => ENV['APOLLO_DB_NAME'],
           :host     => host,
           :port     => port,
           :username => ENV['APOLLO_DB_USER'],
           :password => ENV['APOLLO_DB_PASS']
         )

      # puts "Updating images objects..."
      # q = "select id,value from nodes where node_type_id = 6 and value like '%images%'"
      # image_do = conn.connection().execute(q)
      # image_do.each do |row|
      #    node_id = row[0]
      #    url = row[1]
      #    pid = url.split("%2F").last
      #    pid.gsub!(/\%3A/, ":")
      #    json_val = "{\"type\": \"images\", \"id\": \"#{pid}\"}"
      #    q2 = "update nodes set value='#{json_val}' where id = #{node_id}"
      #    conn.connection().execute(q2)
      # end

      puts "Updating wsls objects..."
      q = "select id,value from nodes where node_type_id = 6 and value like '%wsls%'"
      image_do = conn.connection().execute(q)
      image_do.each do |row|
         node_id = row[0]
         url = row[1]
         pid = url.split("%2F").last
         pid.gsub!(/\%3A/, ":")
         json_val = "{\"type\": \"wsls\", \"id\": \"#{pid}\"}"
         q2 = "update nodes set value='#{json_val}' where id = #{node_id}"
         conn.connection().execute(q2)
      end
   end

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

   desc "Convert WSLS into apollo XML and controlled vocabulary"
   task :compare_wsls  => :environment do
      wsls_csv = File.join(Rails.root, "data", "wsls.csv")
      url_csv = File.join(Rails.root, "data", "wsls-urls.csv")
      main_pids = []
      CSV.foreach(wsls_csv, headers: true) do |row|
         main_pids << row[6]
      end
      cnt = 0
      CSV.foreach(url_csv, headers: true) do |row|
         url_pid = row[0]
         if !main_pids.include? url_pid
            cnt += 1
            puts "URL PID #{url_pid} not found in main WSLS data"
         end
      end
      puts "Found #{cnt} missing PIDS"
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
      month_desc_template = "Video clips and corresponding anchor scripts from #MONTH of #YEAR."
      f = File.open( File.join(Rails.root, "data", "wsls-tree.json") )
      pid_tree = JSON.parse(f.read)
      url_csv = File.join(Rails.root, "data", "wsls-urls.csv")
      months = ["January", "February", "March", "April", "May", "June", "July",
                "August", "September", "October", "November", "December", "Unknown"]
      xml_doc = Nokogiri::XML::Document.new

      puts "Read durations into hash..."
      dur_map = {}
      CSV.foreach(dur_csv, headers: true) do |row|
         dur_map[row[0]] = row[1]
      end

      puts "Read URLS into hash..."
      url_map = {}
      CSV.foreach(url_csv, headers: true) do |row|
         # WSLS_ID, PID, WEBM URL, Streaming Playlist URL,Video Poster URL,
         # Video Thumbnail URL, Anchor Script PDF URL, Anchor Script Transcription URL,
         # Anchor Script Thumbnail URL
         obj = {}
         obj["digitalObject"] = []
         url_map[row[0]] = {video: true, script: !row[6].blank? }
      end

      puts "Create collection node..."
      coll_node = Nokogiri::XML::Node.new "collection", xml_doc
      xml_doc.add_child(coll_node)
      title_node = Nokogiri::XML::Node.new "title", xml_doc
      title_node.content = title
      coll_node.add_child title_node
      desc_node = Nokogiri::XML::Node.new "description", xml_doc
      f = File.open(desc_file, "rb")
      desc_node.content = f.read
      coll_node.add_child desc_node
      f.close
      pid_node = Nokogiri::XML::Node.new "externalPID", xml_doc
      pid_node.content = "uva-lib:2214294"
      coll_node.add_child pid_node
      rights_node = Nokogiri::XML::Node.new "useRights", xml_doc
      rights_node.content = "Copyright Not Evaluated"
      coll_node.add_child rights_node

      puts "Parse main WSLS csv..."
      row_num = 2 # spreadsheet starts at 2
      no_id = 0
      no_data = 0
      data = {}
      CSV.foreach(wsls_csv, headers: true) do |row|
         wsls_id = row[6]
         if wsls_id.blank?
            wsls_id = row[0]
            if wsls_id.blank?
               # puts "WARN: Row #{row_num} has not WSLS ID, skipping"
               no_id +=1
               row_num += 1
               next
            end
         end

         right_status = row[4]
         wsls_src = nil
         if right_status == "L"
            wsls_src = "Local"
         elsif right_status == "T"
            wsls_src = "Telenews"
         end

         wsls_date = row[8]
         if wsls_date.blank? || wsls_date == "n/a"
            year = "unknown"
            month = nil
         else
            # YYYY-mm-dd format
            if wsls_date.include? "/"
               year = wsls_date.split("/").last
               month = wsls_date.split("/").first.to_i
            else
               year = wsls_date.split("-").first
               month = wsls_date.split("-")[1].to_i
            end
            if year.length > 4
               # take the last 4 digits; day and year ran together
               year = year[2..-1]
            end
            if month.to_i == 0
               month = 13
            end
         end

         item = {}
         item["wslsSource"] = wsls_src if !wsls_src.blank?
         item["filmBoxLabel"] = row[11] if !row[11].blank?
         item["title"] = row[12] if !row[12].blank?
         item["abstract"] = row[13] if !row[13].blank?
         topics = []
         topics << row[14] if !row[14].blank?
         topics << row[16] if !row[16].blank?
         topics << row[18] if !row[18].blank?
         item["wslsTopic"] = topics if !topics.blank?

         places = []
         places << row[19] if !row[19].blank?
         places << row[21] if !row[21].blank?
         places << row[22] if !row[22].blank?
         item["wslsPlace"] = places if !places.blank?

         entities = []
         for i in 23..31
            entities << row[i] if !row[i].blank?
         end
         item["entity"] = entities if !entities.blank?

         dur = dur_map[ wsls_id ]
         item["duration"] = dur if !dur.blank?
         item["wslsColor"] = row[34]  if !row[34].blank?
         item["wslsTag"] = row[35] if !row[35].blank?
         ext_pid = row[38]
         if !ext_pid.blank?
            # this is PID for a ITEM (not structure like year or month)
            item["externalPID"] = ext_pid.split("/").last
         end

         # If there is no data for this row, skip it
         if item.keys.count > 0
            item["wslsID"] = wsls_id

            dobjs = url_map[wsls_id]
            if dobjs.blank?
               item["hasVideo"] = false
               item["hasScript"] = false
            else
               item["hasVideo"] = dobjs[:video]
               item["hasScript"] = dobjs[:script]

               # this is a leaf; see if there is a representation
               dov = Settings.doviewer_url
               url = "#{dov}/wsls/#{item['externalPID']}"
               oembed = "#{dov}/oembed?url=#{CGI.escape(url)}"
               item["digitalObject"] = oembed
            end

            # Unknown is special; it doesn't have a month breakdown. Just an array of items
            if year == "unknown"
               if data.has_key? year
                  data[year] << item
               else
                  data[year] = [ item ]
               end
            else
               year_obj = data[year]
               if year_obj.nil?
                  data[year] = {}
                  year_obj = data[year]
               end
               if year_obj.has_key? month
                  year_obj[month] << item
               else
                  year_obj[month] = [ item ]
               end
            end
         else
            # puts "WARN: row #{row_num} has no data, skipping"
            no_data += 1
         end

         row_num +=1
         print "." if row_num%100 == 0
      end

      item_cnt = 0
      data.keys.sort.each do |year|
         puts "  #{year}"
         year_node = Nokogiri::XML::Node.new "year", xml_doc
         coll_node.add_child year_node
         title_node = Nokogiri::XML::Node.new "title", xml_doc
         title_node.content = year
         year_node.add_child title_node
         desc_node = Nokogiri::XML::Node.new "description", xml_doc
         desc_node.content = year_desc_template.gsub(/#YEAR/, year)
         year_node.add_child desc_node
         year_pid = find_year_pid(year, pid_tree)
         if !year_pid.blank?
            pid_node = Nokogiri::XML::Node.new "externalPID", xml_doc
            pid_node.content = year_pid
            year_node.add_child pid_node
         end

         year_ele = data[year]
         if year != "unknown"
            year_ele.keys.sort.each do |month|
               next if month == 0
               month_node = Nokogiri::XML::Node.new "month", xml_doc
               year_node.add_child month_node
               title_node = Nokogiri::XML::Node.new "title", xml_doc
               month_name = months[ month.to_i-1 ]
               title_node.content = month_name
               month_node.add_child title_node
               desc_node = Nokogiri::XML::Node.new "description", xml_doc
               desc_node.content = month_desc_template.gsub(/#YEAR/, year).gsub(/#MONTH/, month_name)
               month_node.add_child desc_node
               month_pid = find_month_pid(year, month_name, pid_tree)
               if !month_pid.blank?
                  pid_node = Nokogiri::XML::Node.new "externalPID", xml_doc
                  pid_node.content = month_pid
                  month_node.add_child pid_node
               end
               puts "    #{month_name}"
               year_ele[month].each do |item|
                  create_item_node(month_node, item)
                  item_cnt+=1
                  print "+" if item_cnt%100 == 0
               end
            end
         else
            year_ele.each do |item|
               create_item_node(year_node, item)
               item_cnt+=1
               print "+" if item_cnt%100 == 0
            end
         end
      end

      puts
      puts "DONE; writing file..."
      File.write("wsls.xml", xml_doc.to_xml)
      puts "TOTAL Rows processed: #{row_num-2}, No ID: #{no_id}, No Data: #{no_data}"
      puts "TOTAL ITEMS: #{item_cnt}"
   end

   def create_item_node(parent, item)
      item_node = Nokogiri::XML::Node.new "item", parent
      parent.add_child item_node
      item.each do |key,val|
         if val.kind_of?(Array)
            val.each do |v|
               child = Nokogiri::XML::Node.new key, parent
               child.content = v
               item_node.add_child child
            end
         else
            child = Nokogiri::XML::Node.new key, parent
            child.content = val
            item_node.add_child child
         end
      end
   end

   def find_month_pid(year, month, tree)
      tree["children"].each do |year_node|
         if year_node["title"] == year
            year_node["children"].each do |month_node|
               if month_node["title"] == month
                  return month_node["id"]
               end
            end
            break
         end
      end
      if month == "February"
         return "uva-lib:2215989" if year == "1966"
         return "uva-lib:2215707" if year == "1967"
         return "uva-lib:2217905" if year == "1970"
         return "uva-lib:2216355" if year == "1971"
      end
      puts "WARNING: No PID found for #{year}/#{month}"
      return ""
   end

   def find_year_pid(year, tree)
      tree["children"].each do |year_node|
         if year_node["title"] == year
            return year_node["id"]
         end
      end
      puts "WARNING: No PID found for #{year}"
      return ""
   end

   desc "Parse out WSLS controlled vocabulary into Apollo ingest files"
   task :wsls_vocab  => :environment do
      topics = {}
      places = {}
      colors = []
      tags = []
      s_cnt = 0
      dups = ["Bedford (Va.)", "James River (Va.)", "Natural Bridge (Va.)", "Roanoke (Va.)", "Salem (Va.)","Smith Mountain Lake (Va.)"]
      wsls_csv = File.join(Rails.root, "data", "wsls.csv")
      CSV.foreach(wsls_csv, headers: true) do |row|
         # O (14) and P (15) are topic val and URI
         topic = row[14]
         if !topic.blank?
            topic.strip!
            next if dups.include? topic
            if !topics.has_key? topic
               topics[topic] = row[15]
            end
         end

         # Q (15) and R (16) are topic/URI too
         topic = row[16]
         if !topic.blank?
            topic.strip!
            next if dups.include? topic
            if !topics.has_key? topic
               topics[topic] = row[17]
            end
         end

         # S is a topic, but has no URI? Throw it away?
         topic = row[18]
         if !topic.blank?
            topic.strip!
            next if dups.include? topic
            if !topics.has_key? topic
               puts "WARN: Controlled vocab for topic [#{topic}] with no URI"
               topics[topic] = ""
            end
         end

         # T (19) and U (20) are place val and URI
         place = row[19]
         if !place.blank?
            place.strip!
            next if place=="Jefferson National Forest"
            if !places.has_key?(place) && !topics.has_key?(place)
               places[place] = row[20]
            end
         end

         [21,22].each do |col_idx|
            val = row[col_idx]
            next if val.blank?
            val.strip!
            next if val=="Jefferson National Forest"
            if !places.has_key?(val) && !topics.has_key?(val)
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
      cv_id = 10
      out = File.open("wsls_topics.sql", "w")
      out.write("insert into controlled_values (id,pid,node_type_id,value,value_uri) values\n  ")
      topics.sort.each_with_index do |ele, idx|
         out.write(",\n  ") if idx > 0
         out.write("(#{cv_id},\"uva-acv#{cv_id}\",15,\"#{ele[0]}\",\"#{ele[1]}\")")
         cv_id+=1
      end
      out.write(";")
      out.close

      puts "Create SQL insert for places..."
      out = File.open("wsls_places.sql", "w")
      out.write("insert into controlled_values (id,pid,node_type_id,value,value_uri) values\n  ")
      places.sort.each_with_index do |ele, idx|
         out.write(",\n  ") if idx > 0
         out.write("(#{cv_id},\"uva-acv#{cv_id}\",16,\"#{ele[0]}\",\"#{ele[1]}\")")
         cv_id+=1
      end
      out.write(";")
      out.close

      puts "Create SQL insert for wslsColor..."
      out = File.open("wsls_color.sql", "w")
      out.write("insert into controlled_values (id,pid,node_type_id,value) values\n  ")
      colors.sort.each_with_index do |ele, idx|
         out.write(",\n  ") if idx > 0
         out.write("(#{cv_id},'uva-acv#{cv_id}',17,'#{ele}')")
         cv_id+=1
      end
      out.write(";")
      out.close

      puts "Create SQL insert for wslsTag..."
      out = File.open("wsls_tag.sql", "w")
      out.write("insert into controlled_values (id,pid,node_type_id,value) values\n  ")
      tags.sort.each_with_index do |ele, idx|
         out.write(",\n  ") if idx > 0
         out.write("(#{cv_id},'uva-acv#{cv_id}',18,'#{ele}')")
         cv_id+=1
      end
      out.write(";")
      out.close
   end
end
