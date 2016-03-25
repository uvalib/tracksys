#encoding: utf-8

namespace :workflow do

   desc "Update tech metadata for issue by PID"
   task :update_tech_metadata => :environment do
      pid = ENV['pid']
      raise "PID is required" if pid.nil?
      cmp = Component.where(pid: pid).first
      raise "Invalid PID" if cmp.nil?

      mfs = MasterFile.where(component_id: cmp.id)
      mfs.each do | mf |
         puts "Update TechMetadata for #{mf.filename}"
         UpdateFedoraDatastreams.exec_now( { :object_class => mf.class.to_s, :object_id => mf.id, :datastream => "tech_metadata" })
      end
   end

   desc "Update solr index for issue by ID"
   task :update_rels_ext => :environment do
      id = ENV['id']
      raise "ID is required" if id.nil?
      cmp = Component.find(id)
      UpdateFedoraDatastreams.exec_now( { :object_class => cmp.class.to_s, :object_id => cmp.id, :datastream => "rels_ext" })
   end

   desc "Update solr index for issue by ID"
   task :update_index => :environment do
      id = ENV['id']
      raise "ID is required" if id.nil?
      cmp = Component.find(id)
      UpdateFedoraDatastreams.exec_now( { :object_class => cmp.class.to_s, :object_id => cmp.id, :datastream => "solr_doc" })
   end

   desc "Update Images for issue by PID"
   task :update_images => :environment do
      pid = ENV['pid']
      raise "PID is required" if pid.nil?
      cmp = Component.where(pid: pid).first
      raise "Invalid PID" if cmp.nil?

      mfs = MasterFile.where(component_id: cmp.id)
      mfs.each do | mf |
         puts "Update Images for #{mf.filename}"
         UpdateFedoraDatastreams.exec_now( { :object_class => mf.class.to_s, :object_id => mf.id, :datastream => "jp2k" })
      end
   end

   desc "Ingest unit from archive"
   task :ingest_unit => :environment do
      id = ENV['id']
      raise "ID is required" if id.nil?
      unit = Unit.find(id)

      puts "   => Start ingest for unit #{unit.id}:#{unit.special_instructions}"
      StartIngestFromArchive.exec_now( { :unit_id => "#{unit.id}" } )
   end

   desc "Create DL Manifest for user cid=computing_id (default = aec6v)"
   task :create_dl_manifest => :environment do
      cid = ENV['cid']
      cid = 'aec6v' if cid.nil?
      puts "   => Create DL Manifest for #{cid}"
      CreateDlManifest.exec_now( { :computing_id => "#{cid}", :deliver=>false } )
   end

   desc "Create stats report for the specified year year=year"
   task :stats_report => :environment do
      year = ENV['year']
      raise "Year is required" if year.nil?
      puts "   => Create stats report for #{year}"
      CreateStatsReport.exec_now( { :year => "#{year}" } )
   end

   desc "Start finalization dir=production|migration"
   task :start_finalization => :environment do
      dir = ENV['dir']
      raise "dir is required" if dir.nil?
      directory = FINALIZATION_DROPOFF_DIR_MIGRATION
      directory = FINALIZATION_DROPOFF_DIR_PRODUCTION if dir == "production"
      puts "   => Start Finalization #{directory}"
      StartFinalization.exec_now( { :directory => "#{directory}" } )
   end

   desc "Start manual upload from=production|migration|batch"
   task :manual_upload => :environment do
      from = ENV['from']
      raise "from is required" if from.nil?
      directory = MANUAL_UPLOAD_TO_ARCHIVE_DIR_BATCH_MIGRATION
      directory = MANUAL_UPLOAD_TO_ARCHIVE_DIR_MIGRATION if from == "migration"
      directory = MANUAL_UPLOAD_TO_ARCHIVE_DIR_PRODUCTION if from == "production"
      puts "   => Start Finalization #{directory}"
      StartManualUploadToArchive.exec_now( { :directory => "#{directory}" } )
   end
end
