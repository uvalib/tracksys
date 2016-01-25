class UpdateFedoraDatastreams < BaseJob

   def perform(message)
      Job_Log.debug "UpdateFedoraDatastreamsProcessor received: #{message.to_json}"

      # Validate incoming message
      raise "Parameter 'object_class' is required" if message[:object_class].blank?
      raise "Parameter 'object_id' is required" if message[:object_id].blank?
      raise "Parameter 'datastream' is required" if message[:datastream].blank?

      @object_class = message[:object_class]
      @object_id = message[:object_id]
      @object = @object_class.classify.constantize.find(@object_id)
      @messagable_id = message[:object_id]
      @messagable_type = message[:object_class]
      set_workflow_type()
      @datastream = message[:datastream]

      if @object.is_a? Unit
         @unit_dir = "%09d" % @object_id

         if @datastream == 'all'
            msg = { :type => 'update', :object_class => @object.bibl.class.to_s, :object_id => @object.bibl.id}
            IngestDescMetadata.exec_now(msg)
            IngestMarc.exec_now(msg)
            IngestRightsMetadata.exec_now(msg)

            if File.exist?(File.join(TEI_ARCHIVE_DIR, "#{@object.bibl.id}.tei.xml"))
               IngestTeiDoc.exec_now(msg)
            end

            instance_variable_set("@#{@object.bibl.class.to_s.underscore}_id", @object.bibl.id)

            # Update the object's date_dl_update value
            @object.bibl.update_attribute(:date_dl_update, Time.now)

            on_success "All datastreams for #{@object.bibl.class.to_s} #{@object.bibl.id} will be updated"

            # Undo instance_variable_set
            instance_variable_set("@#{@object.bibl.class.to_s.underscore}_id", '')

            @object.master_files.each {|mf|
               # Messages coming from this processor should only be for units that have already been archived.
               @source = mf.path_to_archved_version
               msg = { :type => 'update', :object_class => mf.class.to_s, :object_id => mf.id}
               imsg = { :type => 'update', :object_class => mf.class.to_s, :object_id => mf.id, :source => @source, :mode => 'dl', :last => 0 }
               IngestDescMetadata.exec_now(msg)
               IngestRightsMetadata.exec_now(msg)
               IngestTechMetadata.exec_now(msg)
               CreateDlDeliverables.exec_now(imsg)

               if not mf.transcription_text.blank?
                  IngestTranscription.exec_now(msg)
               end
               instance_variable_set("@#{mf.class.to_s.underscore}_id", mf.id)

               # Update the object's date_dl_update value
               mf.update_attribute(:date_dl_update, Time.now)

               on_success "All datastreams for #{mf.class.to_s} #{mf.id} will be updated."

               # Undo instance_variable_set
               instance_variable_set("@#{mf.class.to_s.underscore}_id", '')
            }

            # TODO: Put in update procedures for component

            instance_variable_set("@#{@object.class.to_s.underscore}_id", @object_id)
            on_success "All objects related to #{@object.class.to_s} #{@object_id} are being updated."

            # Undo instance_variable_set
            instance_variable_set("@#{@object.class.to_s.underscore}_id", '')

         elsif @datastream == 'allimages'
            @object.master_files.each {|mf|
               # Messages coming from this processor should only be for units that have already been archived.
               @source = File.join(ARCHIVE_READ_DIR, @unit_dir, mf.filename)

               imsg = { :type => 'update', :object_class => mf.class.to_s, :object_id => mf.id, :source => @source, :last => 0 }
               CreateDlDeliverables.exec_now(imsg) if mf.datastream_exists?("content")
               instance_variable_set("@#{mf.class.to_s.underscore}_id", mf.id)

               # Update the object's date_dl_update value
               mf.update_attribute(:date_dl_update, Time.now)

               on_success "JP2K image for #{mf.class.to_s} #{mf.id} will be regenerated."
               instance_variable_set("@#{mf.class.to_s.underscore}_id", '')
            }
            on_success "All JP2K images for #{@object.class.to_s} #{@object.id} will be updated."

         elsif @datastream == 'desc_metadata'
            IngestDescMetadata.exec_now({ :type => 'update', :object_class => @object.bibl.class.to_s, :object_id => @object.bibl.id})

            instance_variable_set("@#{@object.bibl.class.to_s.underscore}_id", @object.bibl.id)

            # Update the object's bibl's date_dl_update value
            @object.bibl.update_attribute(:date_dl_update, Time.now)

            on_success "The descMetadata datastream for #{@object.bibl.class.to_s} #{@object.bibl.id} will be updated"
            instance_variable_set("@#{@object.bibl.class.to_s.underscore}_id", '')

            @object.master_files.each {|mf|
               IngestDescMetadata.exec_now({ :type => 'update', :object_class => mf.class.to_s, :object_id => mf.id})

               instance_variable_set("@#{mf.class.to_s.underscore}_id", mf.id)

               # Update the MasterFile's date_dl_update value
               mf.update_attribute(:date_dl_update, Time.now)

               on_success "The descMetadata datastream for #{mf.class.to_s} #{mf.id} will be updated"
               instance_variable_set("@#{mf.class.to_s.underscore}_id", '')
            }
         elsif @datastream == 'solr_doc'
            @object.master_files.each {|mf|
               @messagable_id = mf.id
               @messagable_type = "MasterFile"
               IngestSolrDoc.exec_now({ :type => 'update', :object_class => mf.class.to_s, :object_id => mf.id})
               on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} Master Files will be updated."

               # Update the MasterFile's date_dl_update value
               mf.update_attribute(:date_dl_update, Time.now)
            }
         elsif @datastream == 'allxml'
            msg = { :type => 'update', :object_class => @object.bibl.class.to_s, :object_id => @object.bibl.id}
            IngestDescMetadata.exec_now(msg)
            IngestMarc.exec_now(msg)
            IngestRightsMetadata.exec_now(msg)

            if File.exist?(File.join(TEI_ARCHIVE_DIR, "#{@object.bibl.id}.tei.xml"))
               IngestTeiDoc.exec_now(msg)
            end

            instance_variable_set("@#{@object.bibl.class.to_s.underscore}_id", @object.bibl.id)

            # Update the object's bibl's date_dl_update value
            @object.bibl.update_attribute(:date_dl_update, Time.now)

            on_success "All XML datastreams for #{@object.bibl.class.to_s} #{@object.bibl.id} will be updated"
            # Undo instance_variable_set
            instance_variable_set("@#{@object.bibl.class.to_s.underscore}_id", '')

            @object.master_files.each {|mf|
               # Messages coming from this processor should only be for units that have already been archived.
               @source = File.join(ARCHIVE_READ_DIR, @unit_dir, mf.filename)
               msg = { :type => 'update', :object_class => mf.class.to_s, :object_id => mf.id}
               IngestDescMetadata.exec_now(msg)
               IngestRightsMetadata.exec_now( msg )
               IngestTechMetadata.exec_now(msg)

               if not mf.transcription_text.blank?
                  IngestTranscription.exec_now(msg)
               end
               instance_variable_set("@#{mf.class.to_s.underscore}_id", mf.id)

               # Update the MasterFile's date_dl_update value
               mf.update_attribute(:date_dl_update, Time.now)

               on_success "All XML datastreams for #{mf.class.to_s} #{mf.id} will be updated."

               # Undo instance_variable_set
               instance_variable_set("@#{mf.class.to_s.underscore}_id", '')
            }

            # TODO: Put in update procedures for component
         else
            on_error "Datastream variable #{@datastream} is unknown."
         end
      elsif @object.is_a? MasterFile
         instance_variable_set("@#{@object.class.to_s.underscore}_id", @object.id)

         # Update the object's date_dl_update value
         @object.update_attribute(:date_dl_update, Time.now)

         @unit_dir = "%09d" % @object.unit.id

         # Messages coming from this processor should only be for units that have already been archived.
         @source = File.join(@object.archive.directory, @unit_dir, @object.filename)

         mmsg = { :type => 'update', :object_class => @object.class.to_s, :object_id => @object.id}
         imsg = { :type => 'update', :object_class => @object.class.to_s, :object_id => @object.id, :source => @source, :mode => 'dl', :last => 0 }

         if @datastream == 'all'
            IngestDescMetadata.exec_now(mmsg)
            IngestRightsMetadata.exec_now(mmsg)
            IngestTechMetadata.exec_now(mmsg)

            if not @object.transcription_text.blank?
               IngestTranscription.exec_now( mmsg )
            end

            CreateDlDeliverables.exec_now(imsg)
            on_success "All datastreams for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'allxml'
            IngestDescMetadata.exec_now(mmsg)
            IngestRightsMetadata.exec_now(mmsg)
            IngestTechMetadata.exec_now(mmsg)

            if not @object.transcription_text.blank?
               IngestTranscription.exec_now( mmsg )
            end
            on_success "All XML datastreams for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'tech_metadata'
            IngestTechMetadata.exec_now(mmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'transcription'
            IngestTranscription.exec_now( mmsg )
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'desc_metadata'
            IngestDescMetadata.exec_now(mmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'rels_ext'
            IngestRelsExt.exec_now( mmsg )
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'rights_metadata'
            IngestRightsMetadata.exec_now(mmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'dc_metadata'
            IngestDcMetadata.exec_now(mmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'solr_doc'
            IngestSolrDoc.exec_now(mmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'jp2k'
            CreateDlDeliverables.exec_now(imsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         else
            on_error "Datastream variable #{@datastream} is unknown."
         end
      elsif @object.is_a? Bibl
         instance_variable_set("@#{@object.class.to_s.underscore}_id", @object.id)

         # Update the object's date_dl_update value
         @object.update_attribute(:date_dl_update, Time.now)

         bmsg = { :type => 'update', :object_class => @object.class.to_s, :object_id => @object.id }

         if @datastream == 'allxml'
            IngestDescMetadata.exec_now(bmsg)
            if @object.catalog_key
               IngestMarc.exec_now(bmsg)
            end
            IngestRightsMetadata.exec_now(bmsg)

            if File.exist?(File.join(TEI_ARCHIVE_DIR, "#{@object.id}.tei.xml"))
               IngestTeiDoc.exec_now(bmsg)
            end

            on_success "All datastreams for #{@object_class} #{@object_id} will be updated"
         elsif @datastream == 'desc_metadata'
            IngestDescMetadata.exec_now(bmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'rels_ext'
            IngestRelsExt.exec_now( bmsg )
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'marc'
            IngestMarc.exec_now(bmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'rights_metadata'
            IngestRightsMetadata.exec_now(bmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'tei'
            IngestTeiDoc.exec_now(bmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'dc_metadata'
            IngestDcMetadata.exec_now(bmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'solr_doc'
            IngestSolrDoc.exec_now(bmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         end
      elsif @object.is_a? Component
         instance_variable_set("@#{@object.class.to_s.underscore}_id", @object.id)

         # Update the object's date_dl_update value
         @object.update_attribute(:date_dl_update, Time.now)

         cmsg = { :type => 'update', :object_class => @object.class.to_s, :object_id => @object.id}
         component_message = ActiveSupport::JSON.encode(cmsg)

         if @datastream == 'allxml'
            IngestDescMetadata.exec_now(cmsg)
            on_success "All datastreams for #{@object_class} #{@object_id} will be updated"
         elsif @datastream == 'desc_metadata'
            IngestDescMetadata.exec_now(cmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'rels_ext'
            IngestRelsExt.exec_now( cmsg )
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'dc_metadata'
            IngestDcMetadata.exec_now(cmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         elsif @datastream == 'solr_doc'
            IngestSolrDoc.exec_now(cmsg)
            on_success "The #{@datastream} datastream for #{@object_class} #{@object_id} will be updated."
         end
      else
         on_error "Object #{@object_class} #{@object_id} is of an unknown class.  Check incoming message."
      end
   end
end