class BulkDownloadXml < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'user' is required" if message[:user].blank?

      user = message[:user]
      unit = Unit.find(message[:unit_id])
      xml_dir = Finder.xml_directory(unit, :pickup)
      if Dir.exist? xml_dir
         logger.info "Removing old XML pickup directory #{xml_dir}"
         FileUtils.rm_rf(xml_dir)
      end
      FileUtils.mkdir_p(xml_dir)

      cnt = 0
      unit_metadata = unit.metadata
      unit.master_files.each do |mf|
         next if mf.metadata == unit_metadata
         next if mf.metadata.type != "XmlMetadata"

         xml_file = File.join(xml_dir, mf.filename.gsub(/.tif/, ".xml"))
         f = File.open( xml_file, "w")
         f.write( mf.metadata.desc_metadata )
         f.close
         cnt += 1
      end

      NotificationsMailer.xml_download_complete(user, unit, xml_dir).deliver_now
      logger.info "Downloaded XML Metadata from #{cnt} masterfiles to #{xml_dir}"
   end
end
