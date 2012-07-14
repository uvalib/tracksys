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
    :create_dl_deliverables_group => [
      :create_dl_deliverables_processor],
    :create_patron_deliverables_group => [
      :create_patron_deliverables_processor],
    :copy_unit_for_deliverable_generation_group => [
      :copy_unit_for_deliverable_generation_processor],
    :copy_archived_files_to_production_group => [
      :copy_archived_files_to_production_processor,
      :copy_directory_from_archive_processor],
    :create_order_zip_group => [
      :create_order_zip_processor],
    :delete_unit_copy_for_deliverable_generation_group => [
      :delete_unit_copy_for_deliverable_generation_processor],
    :dl_ingestion_group => [
      :create_new_fedora_objects_processor,
      :ingest_dc_metadata_processor,
      :ingest_desc_metadata_processor,
      :ingest_jp2k_processor,
      :ingest_marc_processor,
      :ingest_rels_ext_processor,
      :ingest_rels_int_processor,
      :ingest_rights_metadata_processor,
      :ingest_solr_doc_processor,
      :ingest_tei_doc_processor,
      :ingest_tech_metadata_processor,
      :ingest_transcription_processor,
      :propogate_access_policies_processor,
      :propogate_discoverability_processor,
      :propogate_indexing_scenarios_processor,
      :queue_objects_for_fedora_processor,
      :send_commit_to_solr_processor,
      :update_fedora_datastreams_processor,
      :update_rels_ext_with_indexer_content_model_processor],
    :order_email_group => [
      :create_invoice_processor, 
      :move_deliverables_to_delivered_orders_directory_processor, 
      :send_order_email_processor,
      :update_order_date_customer_notified_processor,
      :update_order_email_date_processor,
      ],
    :lightweight_group => [ :burst_pdf_processor,
      :check_order_date_archiving_complete_processor,
      :check_order_delivery_method_processor, 
      :check_order_fee_processor, 
      :check_order_ready_for_delivery_processor, 
      :check_unit_delivery_mode_processor, 
      :check_units_completed_processor, 
      :copy_metadata_to_metadata_directory_processor, 
      :create_master_file_records_from_tif_and_text_processor,
      :create_order_email_processor, 
      :create_order_pdf_processor, 
      :create_text_from_pdf_processor,
      :create_tif_images_from_pdf_processor,
      :create_stats_report_processor, 
      :import_unit_iview_xml_processor, 
      :move_completed_directory_to_delete_directory_processor, 
      :qa_filesystem_and_iview_xml_processor, 
      :qa_order_data_processor, 
      :qa_unit_data_processor, 
      :queue_unit_deliverables_processor, 
      :replace_or_add_master_files_processor,
      :select_finalization_units_processor, 
      :send_fee_estimate_to_customer_processor,
      :send_pdf_unit_to_finalization_dir_processor,
      :start_finalization_production_processor, 
      :start_finalization_migration_processor, 
      :start_ingest_from_archive_processor, 
      :start_manual_upload_to_archive_production_processor, 
      :start_manual_upload_to_archive_migration_processor, 
      :update_order_date_archiving_complete_processor, 
      :update_order_date_fee_estimate_sent_to_customer_processor, 
      :update_order_date_finalization_begun_processor, 
      :update_order_date_patron_deliverables_complete_processor, 
      :update_order_status_approved_processor,
      :update_order_status_canceled_processor,
      :update_order_status_deferred_processor,
      :update_unit_archive_id_processor, 
      :update_unit_date_archived_processor, 
      :update_unit_date_dl_deliverables_ready_processor, 
      :update_unit_date_patron_deliverables_ready_processor, 
      :update_unit_date_queued_for_ingest_processor,
      :update_unit_status],
    :send_unit_to_archive_group => [
      :send_unit_to_archive_processor],
    :technical_metadata_group => [
      :create_image_technical_metadata_and_thumbnail_processor,
      :purge_cache_processor]
  }

  s.queue :automation_message, '/queue/AutomationMessage' 
  s.queue :burst_pdf, '/queue/BurstPdf'
  s.queue :check_order_date_archiving_complete, '/queue/CheckOrderDateArchivingComplete'
  s.queue :check_order_delivery_method, '/queue/CheckOrderDeliveryMethod'
  s.queue :check_order_fee, '/queue/CheckOrderFee'
  s.queue :check_order_ready_for_delivery, '/queue/CheckOrderReadyForDelivery'
  s.queue :check_unit_delivery_mode, '/queue/CheckUnitDeliveryMode'
  s.queue :check_units_completed, '/queue/CheckUnitsCompleted'
  s.queue :copy_archived_files_to_production, '/queue/CopyArchivedFilesToProduction'
  s.queue :copy_directory_from_archive, '/queue/CopyDirectoryFromArchive'
  s.queue :copy_metadata_to_metadata_directory, '/queue/CopyMetadataToMetadataDirectory'
  s.queue :copy_unit_for_deliverable_generation, '/queue/CopyUnitForDeliverableGeneration'
  s.queue :create_invoice, '/queue/CreateInvoice'
  s.queue :create_master_file_records_from_tif_and_text, '/queue/CreateMasterFileRecordsFromTifAndText'
  s.queue :create_order_email, '/queue/CreateOrderEmail'
  s.queue :create_order_pdf, '/queue/CreateOrderPdf'
  s.queue :create_order_zip, '/queue/CreateOrderZip'
  s.queue :create_new_fedora_objects, '/queue/CreateNewFedoraObjects'
  s.queue :create_image_technical_metadata_and_thumbnail, '/queue/CreateImageTechnicalMetadataAndThumbnail'
  s.queue :create_text_from_pdf, '/queue/CreateTextFromPdf'
  s.queue :create_tif_images_from_pdf, '/queue/CreateTifImagesFromPdf'
  s.queue :create_stats_report, '/queue/CreateStatsReport'
  s.queue :create_dl_deliverables, '/queue/CreateDlDeliverables'  
  s.queue :create_patron_deliverables, '/queue/CreatePatronDeliverables'
  s.queue :delete_unit_copy_for_deliverable_generation, '/queue/DeleteUnitCopyForDeliverableGeneration'  
  s.queue :import_unit_iview_xml, '/queue/ImportUnitIviewXML'
  s.queue :ingest_solr_doc, '/queue/IngestSolrDoc'
  s.queue :ingest_dc_metadata, '/queue/IngestDcMetadata'
  s.queue :ingest_desc_metadata, '/queue/IngestDescMetadata'
  s.queue :ingest_jp2k, '/queue/IngestJp2k'
  s.queue :ingest_marc, '/queue/IngestMarc'
  s.queue :ingest_rels_ext, '/queue/IngestRelsExt'
  s.queue :ingest_rels_int, '/queue/IngestRelsInt'
  s.queue :ingest_rights_metadata, '/queue/IngestRightsMetadata'
  s.queue :ingest_tech_metadata, '/queue/IngestTechMetadata'
  s.queue :ingest_tei_doc, '/queue/IngestTeiDoc'
  s.queue :ingest_transcription, '/queue/IngestTranscription'
  s.queue :move_completed_directory_to_delete_directory, '/queue/MoveCompletedDirectorToDeleteDirectory'
  s.queue :move_deliverables_to_delivered_orders_directory, '/queue/MoveDeliverablesToDeliveredOrdersDirectory'
  s.queue :purge_cache, '/queue/PurgeCache'
  s.queue :propogate_access_policies, '/queue/PropogateAccessPolicies'
  s.queue :propogate_discoverability, '/queue/PropogateDiscoverability'
  s.queue :propogate_indexing_scenarios, '/queue/PropogateIndexingScenario'
  s.queue :qa_filesystem_and_iview_xml, '/queue/QaFilesystemAndIviewXml'
  s.queue :qa_order_data, '/queue/QaOrderData'
  s.queue :qa_unit_data, '/queue/QaUnitData'
  s.queue :queue_objects_for_fedora, '/queue/QueueObjectsForFedora'
  s.queue :queue_unit_deliverables, '/queue/QueueUnitDeliverables'
  s.queue :replace_or_add_master_files, '/queue/ReplaceOrAddMasterFiles'
  s.queue :select_finalization_units, '/queue/SelectFinalizationUnits'
  s.queue :send_commit_to_solr, '/queue/SendCommitToSolr'
  s.queue :send_fee_estimate_to_customer, '/queue/SendFeeEstimateToCustomer'
  s.queue :send_order_email, '/queue/SendOrderEmail'
  s.queue :send_pdf_unit_to_finalization_dir, '/queue/SendPdfUnitToFinalizationDir'
  s.queue :send_unit_to_archive, '/queue/SendUnitToArchive'
  s.queue :start_finalization_production, '/queue/StartFinalizationProduction'
  s.queue :start_finalization_migration, '/queue/StartFinalizationMigration'
  s.queue :start_ingest_from_archive, '/queue/StartIngestFromArchive'
  s.queue :start_manual_upload_to_archive_production, '/queue/StartManuaUploadToArchiveProduction'
  s.queue :start_manual_upload_to_archive_migration, '/queue/StartManuaUploadToArchiveMigration'
  s.queue :update_order_date_archiving_complete, '/queue/UpdateOrderDateArchivingComplete'
  s.queue :update_order_date_customer_notified, '/queue/UpdateOrderDateCustomerNotified'
  s.queue :update_order_date_fee_estimate_sent_to_customer, '/queue/UpdateOrderDateFeeEstimateSentToCustomer'
  s.queue :update_order_date_finalization_begun, '/queue/UpdateOrderDateFinalizationBegun'
  s.queue :update_order_date_patron_deliverables_complete, '/queue/UpdateOrderDatePatronDeliverablesComplete'
  s.queue :update_order_email_date, '/queue/UpdateOrderEmailDate'
  s.queue :update_order_status_approved, '/queue/UpdateOrderStatusApproved'
  s.queue :update_order_status_canceled, '/queue/UpdateOrderStatusCanceled'
  s.queue :update_order_status_deferred, '/queue/UpdateOrderStatusDeferred'
  s.queue :update_rels_ext_with_indexer_content_model, '/queue/UpdateRelsExtWithIndexerContentModel'
  s.queue :update_fedora_datastreams, '/queue/UpdateFedoraDatastreams'
  s.queue :update_unit_archive_id, '/queue/UpdateUnitArchiveId'
  s.queue :update_unit_date_archived, '/queue/UpdateUnitDateArchived'
  s.queue :update_unit_date_dl_deliverables_ready, '/queue/UpdateUnitDateDlDeliverablesReady'
  s.queue :update_unit_date_patron_deliverables_ready, '/queue/UpdateUnitDatePatronDeliverablesReady'
  s.queue :update_unit_date_queued_for_ingest, '/queue/UpdateUnitDateQueuedForIngest'
  s.queue :update_unit_status, '/queue/UpdateUnitStatus'
end
