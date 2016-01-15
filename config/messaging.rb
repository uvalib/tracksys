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
    :create_patron_deliverables_group => [
      :create_patron_deliverables_processor],
    :copy_unit_for_deliverable_generation_group => [
      :copy_unit_for_deliverable_generation_processor],
    :copy_archived_files_to_production_group => [
      :copy_archived_files_to_production_processor,
      :copy_directory_from_archive_processor],
    :dl_ingestion_group => [
      :ingest_rels_int_processor,
      :ingest_rights_metadata_processor,
      :update_fedora_datastreams_processor,
      :update_rels_ext_with_indexer_content_model_processor],
    :dl_ingestion_group_light => [
      :propogate_access_policies_processor,
      :queue_objects_for_fedora_processor
    ],
    :order_email_group => [
      :create_invoice_processor,
      :move_deliverables_to_delivered_orders_directory_processor,
      :send_order_email_processor,
      :update_order_date_customer_notified_processor
      ],
    :lightweight_group => [ :burst_pdf_processor,
      :check_order_date_archiving_complete_processor,
      :check_unit_delivery_mode_processor,
      :check_units_completed_processor,
      :copy_metadata_to_metadata_directory_processor,
      :create_dl_manifest_processor,
      :create_master_file_records_from_tif_and_text_processor,
      :create_text_from_pdf_processor,
      :create_tif_images_from_pdf_processor,
      :create_stats_report_processor,
      :import_unit_iview_xml_processor,
      :move_completed_directory_to_delete_directory_processor,
      :qa_filesystem_and_iview_xml_processor,
      :qa_unit_data_processor,
      :queue_unit_deliverables_processor,
      :replace_or_add_master_files_processor,
      :select_finalization_units_processor,
      :send_fee_estimate_to_customer_processor,
      :send_pdf_unit_to_finalization_dir_processor,
      :start_finalization_production_processor,
      :start_finalization_migration_processor,
      :start_manual_upload_to_archive_batch_migration_processor,
      :start_manual_upload_to_archive_production_processor,
      :start_manual_upload_to_archive_migration_processor,
      :update_order_date_archiving_complete_processor,
      :update_order_date_fee_estimate_sent_to_customer_processor,
      :update_order_date_finalization_begun_processor,
      :update_order_status_approved_processor,
      :update_order_status_canceled_processor,
      :update_order_status_deferred_processor,
      :update_unit_archive_id_processor,
      :update_unit_date_archived_processor,
      :update_unit_status],
    :send_unit_to_archive_group => [
      :send_unit_to_archive_processor],
    :technical_metadata_group => [
      :create_image_technical_metadata_and_thumbnail_processor]
  }

  s.queue :automation_message, '/queue/AutomationMessage'
  s.queue :burst_pdf, '/queue/BurstPdf'
  s.queue :check_order_date_archiving_complete, '/queue/CheckOrderDateArchivingComplete'
  s.queue :check_unit_delivery_mode, '/queue/CheckUnitDeliveryMode'
  s.queue :check_units_completed, '/queue/CheckUnitsCompleted'
  s.queue :copy_archived_files_to_production, '/queue/CopyArchivedFilesToProduction'
  s.queue :copy_directory_from_archive, '/queue/CopyDirectoryFromArchive'
  s.queue :copy_metadata_to_metadata_directory, '/queue/CopyMetadataToMetadataDirectory'
  s.queue :copy_unit_for_deliverable_generation, '/queue/CopyUnitForDeliverableGeneration'
  s.queue :create_invoice, '/queue/CreateInvoice'
  s.queue :create_master_file_records_from_tif_and_text, '/queue/CreateMasterFileRecordsFromTifAndText'
  s.queue :create_dl_manifest, '/queue/CreateDlManifest'
  s.queue :create_text_from_pdf, '/queue/CreateTextFromPdf'
  s.queue :create_tif_images_from_pdf, '/queue/CreateTifImagesFromPdf'
  s.queue :create_stats_report, '/queue/CreateStatsReport'
  s.queue :create_patron_deliverables, '/queue/CreatePatronDeliverables'
  s.queue :import_unit_iview_xml, '/queue/ImportUnitIviewXML'
  s.queue :ingest_rels_int, '/queue/IngestRelsInt'
  s.queue :ingest_rights_metadata, '/queue/IngestRightsMetadata'
  s.queue :move_completed_directory_to_delete_directory, '/queue/MoveCompletedDirectorToDeleteDirectory'
  s.queue :move_deliverables_to_delivered_orders_directory, '/queue/MoveDeliverablesToDeliveredOrdersDirectory'
  s.queue :purge_cache, '/queue/PurgeCache'
  s.queue :qa_filesystem_and_iview_xml, '/queue/QaFilesystemAndIviewXml'
  s.queue :qa_unit_data, '/queue/QaUnitData'
  s.queue :queue_unit_deliverables, '/queue/QueueUnitDeliverables'
  s.queue :replace_or_add_master_files, '/queue/ReplaceOrAddMasterFiles'
  s.queue :select_finalization_units, '/queue/SelectFinalizationUnits'
  s.queue :send_fee_estimate_to_customer, '/queue/SendFeeEstimateToCustomer'
  s.queue :send_order_email, '/queue/SendOrderEmail'
  s.queue :send_pdf_unit_to_finalization_dir, '/queue/SendPdfUnitToFinalizationDir'
  s.queue :send_unit_to_archive, '/queue/SendUnitToArchive'
  s.queue :start_finalization_production, '/queue/StartFinalizationProduction'
  s.queue :start_finalization_migration, '/queue/StartFinalizationMigration'
  s.queue :start_manual_upload_to_archive_batch_migration, '/queue/StartManuaUploadToArchiveBatchMigration'
  s.queue :start_manual_upload_to_archive_production, '/queue/StartManuaUploadToArchiveProduction'
  s.queue :start_manual_upload_to_archive_migration, '/queue/StartManuaUploadToArchiveMigration'
  s.queue :update_order_date_archiving_complete, '/queue/UpdateOrderDateArchivingComplete'
  s.queue :update_order_date_customer_notified, '/queue/UpdateOrderDateCustomerNotified'
  s.queue :update_order_date_fee_estimate_sent_to_customer, '/queue/UpdateOrderDateFeeEstimateSentToCustomer'
  s.queue :update_order_date_finalization_begun, '/queue/UpdateOrderDateFinalizationBegun'
  s.queue :update_order_status_approved, '/queue/UpdateOrderStatusApproved'
  s.queue :update_order_status_canceled, '/queue/UpdateOrderStatusCanceled'
  s.queue :update_order_status_deferred, '/queue/UpdateOrderStatusDeferred'
  s.queue :update_rels_ext_with_indexer_content_model, '/queue/UpdateRelsExtWithIndexerContentModel'
  s.queue :update_fedora_datastreams, '/queue/UpdateFedoraDatastreams'
  s.queue :update_unit_archive_id, '/queue/UpdateUnitArchiveId'
  s.queue :update_unit_date_archived, '/queue/UpdateUnitDateArchived'
  s.queue :update_unit_status, '/queue/UpdateUnitStatus'
end
