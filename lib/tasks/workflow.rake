#encoding: utf-8

namespace :workflow do

   desc "Ingest unit from archive"
   task :ingest_unit => :environment do
      id = ENV['id']
      raise "ID is required" if id.nil?
      unit = Unit.find(id)

      puts "   => Start ingest for unit #{unit.id}:#{unit.special_instructions}"
      StartIngestFromArchive.exec_now( { :unit => unit } )
   end

   desc "Create DL Manifest for user cid=computing_id (default = aec6v)"
   task :create_dl_manifest => :environment do
      cid = ENV['cid']
      cid = 'aec6v' if cid.nil?
      puts "   => Create DL Manifest for #{cid}"
      staff = StaffMember.where(:computing_id => cid).first
      CreateDlManifest.exec_now( { :staff_member => staff, :deliver=>false } )
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
