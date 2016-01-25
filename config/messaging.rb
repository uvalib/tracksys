ActiveMessaging::Gateway.define do |s|
  #s.destination :orders, '/queue/Orders'
  #s.filter :some_filter, :only=>:orders
  #s.processor_group :group1, :order_processor

  # messages are grouped in order to reduce
  # the number of processors launched in app
  # processors are launched by script invoking
  # each by name using script/poller command

  s.processor_groups = {
    :messages_group => [
      :automation_message_processor],
    :cache_management_group => [
      :purge_cache_processor],
    :copy_archived_files_to_production_group => [
      :copy_directory_from_archive_processor],
    :dl_ingestion_group => [
      :ingest_rels_int_processor,
      :update_rels_ext_with_indexer_content_model_processor],
    :dl_ingestion_group_light => [
      :propogate_access_policies_processor,
      :queue_objects_for_fedora_processor
    ],
    :lightweight_group => [ :burst_pdf_processor,
      :check_units_completed_processor,
      :create_master_file_records_from_tif_and_text_processor,
      :create_text_from_pdf_processor,
      :create_tif_images_from_pdf_processor,
      :create_stats_report_processor,
      :replace_or_add_master_files_processor,
      :select_finalization_units_processor,
      :send_pdf_unit_to_finalization_dir_processor,
      :start_manual_upload_to_archive_batch_migration_processor,
      :start_manual_upload_to_archive_production_processor,
      :start_manual_upload_to_archive_migration_processor,
      :update_unit_status],
    :technical_metadata_group => [
      :create_image_technical_metadata_and_thumbnail_processor]
  }

  s.queue :automation_message, '/queue/AutomationMessage'
  s.queue :burst_pdf, '/queue/BurstPdf'
  s.queue :check_units_completed, '/queue/CheckUnitsCompleted'
  s.queue :copy_directory_from_archive, '/queue/CopyDirectoryFromArchive'
  s.queue :create_master_file_records_from_tif_and_text, '/queue/CreateMasterFileRecordsFromTifAndText'
  s.queue :create_text_from_pdf, '/queue/CreateTextFromPdf'
  s.queue :create_tif_images_from_pdf, '/queue/CreateTifImagesFromPdf'
  s.queue :create_stats_report, '/queue/CreateStatsReport'
  s.queue :ingest_rels_int, '/queue/IngestRelsInt'
  s.queue :purge_cache, '/queue/PurgeCache'
  s.queue :replace_or_add_master_files, '/queue/ReplaceOrAddMasterFiles'
  s.queue :select_finalization_units, '/queue/SelectFinalizationUnits'
  s.queue :send_pdf_unit_to_finalization_dir, '/queue/SendPdfUnitToFinalizationDir'
  s.queue :start_manual_upload_to_archive_batch_migration, '/queue/StartManuaUploadToArchiveBatchMigration'
  s.queue :start_manual_upload_to_archive_production, '/queue/StartManuaUploadToArchiveProduction'
  s.queue :start_manual_upload_to_archive_migration, '/queue/StartManuaUploadToArchiveMigration'
  s.queue :update_rels_ext_with_indexer_content_model, '/queue/UpdateRelsExtWithIndexerContentModel'
  s.queue :update_unit_status, '/queue/UpdateUnitStatus'
end
