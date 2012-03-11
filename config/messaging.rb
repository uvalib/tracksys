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
      :create_image_technical_metadata_and_thumbnail_processor]
  }

  s.destination :automation_message, '/queue/AutomationMessage' 
  s.destination :burst_pdf, '/queue/BurstPdf'
  s.destination :check_order_date_archiving_complete, '/queue/CheckOrderDateArchivingComplete'
  s.destination :check_order_delivery_method, '/queue/CheckOrderDeliveryMethod'
  s.destination :check_order_fee, '/queue/CheckOrderFee'
  s.destination :check_order_ready_for_delivery, '/queue/CheckOrderReadyForDelivery'
  s.destination :check_unit_delivery_mode, '/queue/CheckUnitDeliveryMode'
  s.destination :check_units_completed, '/queue/CheckUnitsCompleted'
  s.destination :copy_archived_files_to_production, '/queue/CopyArchivedFilesToProduction'
  s.destination :copy_directory_from_archive, '/queue/CopyDirectoryFromArchive'
  s.destination :copy_metadata_to_metadata_directory, '/queue/CopyMetadataToMetadataDirectory'
  s.destination :copy_unit_for_deliverable_generation, '/queue/CopyUnitForDeliverableGeneration'
  s.destination :create_invoice, '/queue/CreateInvoice'
  s.destination :create_master_file_records_from_tif_and_text, '/queue/CreateMasterFileRecordsFromTifAndText'
  s.destination :create_order_email, '/queue/CreateOrderEmail'
  s.destination :create_order_pdf, '/queue/CreateOrderPdf'
  s.destination :create_order_zip, '/queue/CreateOrderZip'
  s.destination :create_new_fedora_objects, '/queue/CreateNewFedoraObjects'
  s.destination :create_image_technical_metadata_and_thumbnail, '/queue/CreateImageTechnicalMetadataAndThumbnail'
  s.destination :create_text_from_pdf, '/queue/CreateTextFromPdf'
  s.destination :create_tif_images_from_pdf, '/queue/CreateTifImagesFromPdf'
  s.destination :create_stats_report, '/queue/CreateStatsReport'
  s.destination :create_dl_deliverables, '/queue/CreateDlDeliverables'  
  s.destination :create_patron_deliverables, '/queue/CreatePatronDeliverables'
  s.destination :delete_unit_copy_for_deliverable_generation, '/queue/DeleteUnitCopyForDeliverableGeneration'  
  s.destination :import_unit_iview_xml, '/queue/ImportUnitIviewXML'
  s.destination :ingest_solr_doc, '/queue/IngestSolrDoc'
  s.destination :ingest_dc_metadata, '/queue/IngestDcMetadata'
  s.destination :ingest_desc_metadata, '/queue/IngestDescMetadata'
  s.destination :ingest_jp2k, '/queue/IngestJp2k'
  s.destination :ingest_marc, '/queue/IngestMarc'
  s.destination :ingest_rels_ext, '/queue/IngestRelsExt'
  s.destination :ingest_rels_int, '/queue/IngestRelsInt'
  s.destination :ingest_rights_metadata, '/queue/IngestRightsMetadata'
  s.destination :ingest_tech_metadata, '/queue/IngestTechMetadata'
  s.destination :ingest_tei_doc, '/queue/IngestTeiDoc'
  s.destination :ingest_transcription, '/queue/IngestTranscription'
  s.destination :move_completed_directory_to_delete_directory, '/queue/MoveCompletedDirectorToDeleteDirectory'
  s.destination :move_deliverables_to_delivered_orders_directory, '/queue/MoveDeliverablesToDeliveredOrdersDirectory'
  s.destination :propogate_access_policies, '/queue/PropogateAccessPolicies'
  s.destination :propogate_discoverability, '/queue/PropogateDiscoverability'
  s.destination :propogate_indexing_scenarios, '/queue/PropogateIndexingScenario'
  s.destination :qa_filesystem_and_iview_xml, '/queue/QaFilesystemAndIviewXml'
  s.destination :qa_order_data, '/queue/QaOrderData'
  s.destination :qa_unit_data, '/queue/QaUnitData'
  s.destination :queue_objects_for_fedora, '/queue/QueueObjectsForFedora'
  s.destination :queue_unit_deliverables, '/queue/QueueUnitDeliverables'
  s.destination :replace_or_add_master_files, '/queue/ReplaceOrAddMasterFiles'
  s.destination :select_finalization_units, '/queue/SelectFinalizationUnits'
  s.destination :send_commit_to_solr, '/queue/SendCommitToSolr'
  s.destination :send_fee_estimate_to_customer, '/queue/SendFeeEstimateToCustomer'
  s.destination :send_order_email, '/queue/SendOrderEmail'
  s.destination :send_pdf_unit_to_finalization_dir, '/queue/SendPdfUnitToFinalizationDir'
  s.destination :send_unit_to_archive, '/queue/SendUnitToArchive'
  s.destination :start_finalization_production, '/queue/StartFinalizationProduction'
  s.destination :start_finalization_migration, '/queue/StartFinalizationMigration'
  s.destination :start_ingest_from_archive, '/queue/StartIngestFromArchive'
  s.destination :start_manual_upload_to_archive_production, '/queue/StartManuaUploadToArchiveProduction'
  s.destination :start_manual_upload_to_archive_migration, '/queue/StartManuaUploadToArchiveMigration'
  s.destination :update_order_date_archiving_complete, '/queue/UpdateOrderDateArchivingComplete'
  s.destination :update_order_date_customer_notified, '/queue/UpdateOrderDateCustomerNotified'
  s.destination :update_order_date_fee_estimate_sent_to_customer, '/queue/UpdateOrderDateFeeEstimateSentToCustomer'
  s.destination :update_order_date_finalization_begun, '/queue/UpdateOrderDateFinalizationBegun'
  s.destination :update_order_date_patron_deliverables_complete, '/queue/UpdateOrderDatePatronDeliverablesComplete'
  s.destination :update_order_email_date, '/queue/UpdateOrderEmailDate'
  s.destination :update_order_status_approved, '/queue/UpdateOrderStatusApproved'
  s.destination :update_order_status_canceled, '/queue/UpdateOrderStatusCanceled'
  s.destination :update_order_status_deferred, '/queue/UpdateOrderStatusDeferred'
  s.destination :update_rels_ext_with_indexer_content_model, '/queue/UpdateRelsExtWithIndexerContentModel'
  s.destination :update_fedora_datastreams, '/queue/UpdateFedoraDatastreams'
  s.destination :update_unit_archive_id, '/queue/UpdateUnitArchiveId'
  s.destination :update_unit_date_archived, '/queue/UpdateUnitDateArchived'
  s.destination :update_unit_date_dl_deliverables_ready, '/queue/UpdateUnitDateDlDeliverablesReady'
  s.destination :update_unit_date_patron_deliverables_ready, '/queue/UpdateUnitDatePatronDeliverablesReady'
  s.destination :update_unit_date_queued_for_ingest, '/queue/UpdateUnitDateQueuedForIngest'
  s.destination :update_unit_status, '/queue/UpdateUnitStatus'
end
