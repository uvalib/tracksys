namespace :sms do
   desc "dump our mountain work as XML"
   task :omw  => :environment do
      component = Component.find(511278)
      doc = Nokogiri::XML::Document.new
      coll = Nokogiri::XML::Node.new "collection", doc
      doc.add_child(coll)
      root = doc.root
      title = Nokogiri::XML::Node.new "title", doc
      title.content = component.title
      root.add_child title

      # our montain work structure is collection, volume, issue. Volume has a title
      Component.where(:parent_component_id => component.id).each do |vol|
         vol_node = Nokogiri::XML::Node.new "volume", doc
         v_title = Nokogiri::XML::Node.new "title", doc
         v_title.content = vol.title
         vol_node.add_child(v_title)
         coll.add_child(vol_node)

         # each volume has issues
         Component.where(:parent_component_id => vol.id).each do |iss|
            iss_node = Nokogiri::XML::Node.new "issue", doc
            iss_node.content = iss.title
            vol_node.add_child(iss_node)
         end
      end
      puts doc.to_xml
   end
end
