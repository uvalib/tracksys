namespace :migrate do
   desc "Migrate bibls into sirsi and xml metadata"
   task :xml  => :environment do
       puts "Creating XML Metadata records from metadata"
       Metadata.find_each do |metadata|
         if !metadata.desc_metadata.blank? && metadata.desc_metadata.include?("xml version")
            metadata.update(type: "XmlMetadata", discoverability: false)
         end
       end
   end

   task :unit_metadata_to_mf  => :environment do
      puts "Flagging all masterfiles wit metadata from unit"
      Unit.where('metadata_id is not null').order(id: :asc).find_each do |u|
         next if u.master_files.size == 0
         sql = "update master_files set metadata_id=#{u.metadata_id} where master_files.unit_id=#{u.id}"
         ActiveRecord::Base.connection.execute(sql)
      end
   end

   task :mf_desc_metadata  => :environment do
      puts "Creating XML Metadata records from masterfile desc_metadata"
      MasterFile.where("desc_metadata <> '' and desc_metadata is not null").find_each do |mf|
         next if mf.metadata.master_files.first == mf

         # get original metadata availability_policy
         availability_policy = mf.metadata.availability_policy

         title = mf.title
         xml = Nokogiri::XML( mf.desc_metadata )
         xml.remove_namespaces!
         title_node = xml.xpath( "//titleInfo/title" ).first
         if !title_node.nil?
            title = title_node.text.strip
         end
         creator = nil
         creator_node = xml.xpath("//name/namePart").first
         creator = creator_node.text.strip if !creator_node.nil?

         title = "Master File #{mf.id}" if title.blank?

         metadata = Metadata.create!(type: "XmlMetadata", title: title, is_approved: 1,
            discoverability: mf.discoverability, indexing_scenario_id: mf.indexing_scenario_id,
            desc_metadata: mf.desc_metadata, use_right_id: mf.use_right_id,
            availability_policy: availability_policy,
            creator_name: creator, exemplar: mf.filename, pid: mf.pid,
            date_dl_ingest: mf.date_dl_ingest, date_dl_update: mf.date_dl_update )
         puts "Created metadata #{metadata.id} title: #{metadata.title} for MF #{mf.id}"
         mf.update(metadata_id: metadata.id)
      end
   end

   task :mf_fix  => :environment do
      id = ENV['id']
      mf = MasterFile.find(id)

      title = mf.title
      xml = Nokogiri::XML( mf.desc_metadata )
      xml.remove_namespaces!
      title_node = xml.xpath( "//titleInfo/title" ).first
      if !title_node.nil?
         title = title_node.text.strip
      end
      creator = nil
      creator_node = xml.xpath("//name/namePart").first
      creator = creator_node.text.strip if !creator_node.nil?
      availability_policy = mf.metadata.availability_policy
   end

   task :mf_create_meta  => :environment do
      id = ENV['id']
      mf = MasterFile.find(id)

      title = mf.title
      xml = Nokogiri::XML( mf.desc_metadata )
      xml.remove_namespaces!
      title_node = xml.xpath( "//titleInfo/title" ).first
      if !title_node.nil?
         title = title_node.text.strip
      end
      creator = nil
      creator_node = xml.xpath("//name/namePart").first
      creator = creator_node.text.strip if !creator_node.nil?

      mf.metadata.update(title: title, creator_name: creator)
      mf.update(title: title)
      metadata = Metadata.create!(type: "XmlMetadata", title: title, is_approved: 1,
         discoverability: mf.discoverability, indexing_scenario_id: mf.indexing_scenario_id,
         desc_metadata: mf.desc_metadata, use_right_id: mf.use_right_id,
         availability_policy: availability_policy,
         creator_name: creator, exemplar: mf.filename, pid: mf.pid,
         date_dl_ingest: mf.date_dl_ingest, date_dl_update: mf.date_dl_update )
      puts "Created metadata #{metadata.id} title: #{metadata.title} for MF #{mf.id}"
      mf.update(metadata_id: metadata.id)
   end

   task :pids  => :environment do
      puts "fixing pids"
      MasterFile.where("desc_metadata <> '' and desc_metadata is not null").find_each do |mf|
         puts "Assign MF #{mf.id} pid #{mf.pid} to metadata #{mf.metadata.id}"
         mf.metadata.update(pid: mf.pid)
      end
   end
end
