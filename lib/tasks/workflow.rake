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
end
