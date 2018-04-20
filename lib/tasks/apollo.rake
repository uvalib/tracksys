namespace :apollo do
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
      File.write("dail_progress.xml", doc.to_xml)
   end

   desc "dump our mountain work as XML"
   task :omw  => :environment do
      component = Component.find(511278)
      doc = Nokogiri::XML::Document.new
      root = doc.root

      puts "Generating our mountain work XML..."
      struct = ["collection","volume","issue"]
      traverse(struct, doc, component, 0, doc)
      puts
      puts "DONE"

      puts doc.to_xml
   end

   def traverse(struct, xml_doc, curr_component, depth, curr_node)
      # Create node and add title
      child_node = Nokogiri::XML::Node.new struct[depth], xml_doc
      curr_node.add_child(child_node)
      title = Nokogiri::XML::Node.new "title", xml_doc
      title.content = curr_component.title
      child_node.add_child title

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
         # this is a leaf; see if there is a representation
         dov = Settings.doviewer_url
         url = "#{dov}/images/#{curr_component.pid}"
         oembed = "#{dov}/oembed?url=#{CGI.escape(url)}"

         # add digitalObject node with oembed URL
         dobj = Nokogiri::XML::Node.new "digitalObject", xml_doc
         url = "#{dov}/images/#{curr_component.pid}"
         dobj.content = oembed
         child_node.add_child(dobj)
      end

   end
end
