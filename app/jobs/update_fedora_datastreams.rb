class UpdateFedoraDatastreams < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=> message[:object_class], :originator_id=>message[:object_id])
   end

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'object_class' is required" if message[:object_class].blank?
      raise "Parameter 'object_id' is required" if message[:object_id].blank?
      raise "Parameter 'datastream' is required" if message[:datastream].blank?

      @object_class = message[:object_class]
      @object_id = message[:object_id]
      @object = @object_class.classify.constantize.find(@object_id)
      @datastream = message[:datastream]

      if @object.is_a? Unit
         update_unit_datastreams()
      elsif @object.is_a? MasterFile
         update_master_file_datastreams()
      elsif @object.is_a? Bibl
         update_bibl_datastreams()
      elsif @object.is_a? Component
         update_component_datastreams()
      else
         on_error "Object #{@object_class} #{@object_id} is of an unknown class.  Check incoming message."
      end
   end

   # Update datastreams for units
   #
   def update_unit_datastreams()
      @unit_dir = "%09d" % @object_id

      if @datastream == 'all'
         msg = { :object=> @object.bibl}
         IngestDescMetadata.exec_now(msg, self)
         IngestMarc.exec_now(msg, self)
         IngestRightsMetadata.exec_now(msg, self)
         @object.bibl.update_attribute(:date_dl_update, Time.now)

         logger().info "All datastreams for #{@object.bibl.class.to_s} #{@object.bibl.id} have been updated"

         @object.master_files.each do |mf|
            # Messages coming from this processor should only be for units that have already been archived.
            @source = mf.path_to_archved_version
            msg = { :object=> mf }
            imsg = { :object=> mf, :source => @source, :mode => 'dl', :last => 0 }
            IngestDescMetadata.exec_now(msg, self)
            IngestRightsMetadata.exec_now(msg, self)
            IngestTechMetadata.exec_now(msg, self)
            CreateDlDeliverables.exec_now(imsg, self)

            if not mf.transcription_text.blank?
               IngestTranscription.exec_now(msg, self)
            end

            # Update the object's date_dl_update value
            mf.update_attribute(:date_dl_update, Time.now)

            logger().info "All datastreams for #{mf.class.to_s} #{mf.id} have been updated."
         end

         on_success "All objects related to #{@object.class.to_s} #{@object_id} are being updated."

      elsif @datastream == 'allimages'
         @object.master_files.each do |mf|
            # Messages coming from this processor should only be for units that have already been archived.
            @source = File.join(ARCHIVE_DIR, @unit_dir, mf.filename)

            imsg = { :object=>mf, :source => @source, :last => 0 }
            CreateDlDeliverables.exec_now(imsg, self) if mf.datastream_exists?("content")

            # Update the object's date_dl_update value
            mf.update_attribute(:date_dl_update, Time.now)

            on_success "JP2K image for #{mf.class.to_s} #{mf.id} will be regenerated."
         end
         on_success "All JP2K images for #{@object.class.to_s} #{@object.id} will be updated."

      elsif @datastream == 'desc_metadata'
         IngestDescMetadata.exec_now({ :object=>@object.bibl }, self)
         @object.bibl.update_attribute(:date_dl_update, Time.now)
         @object.master_files.each do |mf|
            IngestDescMetadata.exec_now({ :object=>mf }, self)
            mf.update_attribute(:date_dl_update, Time.now)
         end
      elsif @datastream == 'solr_doc'
         @object.master_files.each do |mf|
            IngestSolrDoc.exec_now({ :object=>mf}, self)
            mf.update_attribute(:date_dl_update, Time.now)
         end
      elsif @datastream == 'allxml'
         msg = { :object => @object.bibl }
         IngestDescMetadata.exec_now(msg, self)
         IngestMarc.exec_now(msg, self)
         IngestRightsMetadata.exec_now(msg, self)

         # Update the object's bibl's date_dl_update value
         @object.bibl.update_attribute(:date_dl_update, Time.now)

         @object.master_files.each do |mf|
            msg = { :object=> mf }
            IngestDescMetadata.exec_now(msg, self)
            IngestRightsMetadata.exec_now( msg, self )
            IngestTechMetadata.exec_now(msg, self)

            if not mf.transcription_text.blank?
               IngestTranscription.exec_now(msg, self)
            end
            # Update the MasterFile's date_dl_update value
            mf.update_attribute(:date_dl_update, Time.now)
         end
      else
         on_error "Datastream variable #{@datastream} is unknown."
      end
   end

   # update MASTERFILE Datastreams
   #
   def update_master_file_datastreams()
      @object.update_attribute(:date_dl_update, Time.now)
      @unit_dir = "%09d" % @object.unit.id

      # Messages coming from this processor should only be for units that have already been archived.
      @source = File.join(ARCHIVE_DIR, @unit_dir, @object.filename)

      mmsg = { :object => @object}
      imsg = { :object=> @object, :source => @source, :mode => 'dl', :last => 0 }

      if @datastream == 'all'
         IngestDescMetadata.exec_now(mmsg, self)
         IngestRightsMetadata.exec_now(mmsg, self)
         IngestTechMetadata.exec_now(mmsg, self)

         if not @object.transcription_text.blank?
            IngestTranscription.exec_now( mmsg, self )
         end

         CreateDlDeliverables.exec_now(imsg, self)
         on_success "All datastreams for #{@object_class} #{@object_id} have been updated."
      elsif @datastream == 'allxml'
         IngestDescMetadata.exec_now(mmsg, self)
         IngestRightsMetadata.exec_now(mmsg, self)
         IngestTechMetadata.exec_now(mmsg, self)

         if not @object.transcription_text.blank?
            IngestTranscription.exec_now( mmsg, self )
         end
         on_success "All XML datastreams for #{@object_class} #{@object_id} have been updated."
      elsif @datastream == 'tech_metadata'
         IngestTechMetadata.exec_now(mmsg, self)
      elsif @datastream == 'transcription'
         IngestTranscription.exec_now( mmsg, self )
      elsif @datastream == 'desc_metadata'
         IngestDescMetadata.exec_now(mmsg, self)
      elsif @datastream == 'rels_ext'
         IngestRelsExt.exec_now( mmsg, self )
      elsif @datastream == 'rights_metadata'
         IngestRightsMetadata.exec_now(mmsg, self)
      elsif @datastream == 'dc_metadata'
         IngestDcMetadata.exec_now(mmsg, self)
      elsif @datastream == 'solr_doc'
         IngestSolrDoc.exec_now(mmsg, self)
      elsif @datastream == 'jp2k'
         CreateDlDeliverables.exec_now(imsg, self)
      else
         on_error "Datastream variable #{@datastream} is unknown."
      end
   end

   # Update BIBL datastreams
   #
   def update_bibl_datastreams()
      @object.update_attribute(:date_dl_update, Time.now)
      bmsg = { :object => @object }
      if @datastream == 'allxml'
         IngestDescMetadata.exec_now(bmsg, self)
         if @object.catalog_key
            IngestMarc.exec_now(bmsg, self)
         end
         IngestRightsMetadata.exec_now(bmsg, self)
      elsif @datastream == 'desc_metadata'
         IngestDescMetadata.exec_now(bmsg, self)
      elsif @datastream == 'rels_ext'
         IngestRelsExt.exec_now( bmsg, self )
      elsif @datastream == 'marc'
         IngestMarc.exec_now(bmsg, self)
      elsif @datastream == 'rights_metadata'
         IngestRightsMetadata.exec_now(bmsg, self)
      elsif @datastream == 'tei'
         IngestTeiDoc.exec_now(bmsg, self)
      elsif @datastream == 'dc_metadata'
         IngestDcMetadata.exec_now(bmsg, self)
      elsif @datastream == 'solr_doc'
         IngestSolrDoc.exec_now(bmsg, self)
      else
         on_error "Datastream variable #{@datastream} is unknown."
      end
   end

   # Update COMPONENT datastreams
   #
   def update_component_datastreams()
      @object.update_attribute(:date_dl_update, Time.now)

      cmsg = { :object => @object }
      if @datastream == 'allxml'
         IngestDescMetadata.exec_now(cmsg, self)
      elsif @datastream == 'desc_metadata'
         IngestDescMetadata.exec_now(cmsg, self)
      elsif @datastream == 'rels_ext'
         IngestRelsExt.exec_now( cmsg, self )
      elsif @datastream == 'dc_metadata'
         IngestDcMetadata.exec_now(cmsg, self)
      elsif @datastream == 'solr_doc'
         cmsg[:cascade] = message[:cascade]
         IngestSolrDoc.exec_now(cmsg, self)
      else
         on_error "Datastream variable #{@datastream} is unknown."
      end
   end
end
