require "#{Hydraulics.models_dir}/automation_message"

class AutomationMessage
  APPS.push('tracksys')

  WORKFLOW_TYPES_HASH = {
    'CreateDlManifestProcessor' => 'administrative',
    'CreateStatsReportProcessor' => 'administrative', 
    'SendUnitToArchiveProcessor' => 'archive',
    'StartManualUploadToArchiveMigrationProcessor' => 'archive',
    'StartManualUploadToArchiveBatchMigrationProcessor' => 'archive',
    'StartManualUploadToArchiveProcessor' => 'archive',
    'StartManualUploadToArchiveProductionProcessor' => 'archive',
    'UpdateOrderDateArchivingCompleteProcessor' => 'archive',
    'UpdateUnitArchiveIdProcessor' => 'archive',
    'UpdateUnitDateArchivedProcessor' => 'archive',
    'CreateDlDeliverablesProcessor' => 'repository',
    'CreateNewFedoraObjectsProcessor' => 'repository',
    'IngestDcMetadataProcessor' => 'repository',
    'IngestDescMetadataProcessor' => 'repository',
    'IngestJp2kProcessor' => 'repository',
    'IngestMarcProcessor' => 'repository',
    'IngestRelsExtProcessor' => 'repository',
    'IngestRelsIntProcessor' => 'repository',
    'IngestRightsMetadataProcessor' => 'repository',
    'IngestSolrDocProcessor' => 'repository',
    'IngestTechMetadataProcessor' => 'repository',
    'IngestTranscriptionProcessor' => 'repository',
    'PropogateAccessPoliciesProcessor' => 'repository',
    'PropogateDiscoverabilityProcessor' => 'repository',
    'PropogateIndexingScenariosProcessor' => 'repository',
    'QueueObjectsForFedoraProcessor' => 'repository',
    'SendCommitToSolrProcessor' => 'repository',
    'StartIngestFromArchiveProcessor' => 'repository',
    'UpdateFedoraDatastreamsProcessor' => 'repository',
    'UpdateUnitDateDlDeliverablesReadyProcessor' => 'repository',
    'UpdateUnitDateQueuedForIngestProcessor' => 'repository',
    'CheckUnitDeliveryModeProcessor' => 'qa',
    'CopyMetadataToMetadataDirectoryProcessor' => 'qa',
    'CopyUnitForDeliverableGenerationProcessor' => 'delivery',
    'ImportUnitIviewXMLProcessor' => 'qa',
    'QaFilesystemAndIviewXmlProcessor' => 'qa',
    'QaOrderDataProcessor' => 'qa',
    'QaUnitDataProcessor' => 'qa',
    'StartFinalizationMigrationProcessor' => 'qa',
    'StartFinalizationProcessor' => 'qa',
    'StartFinalizationProductionProcessor' => 'qa',
    'UpdateOrderDateFinalizationBegunProcessor' => 'qa',
    'CopyArchivedFilesToProductionProcessor' => 'patron',
    'CopyDirectoryFromArchiveProcessor' => 'patron',
    'SendFeeEstimateToCustomerProcessor' => 'patron',
    'UpdateOrderDateFeeEstimateSentToCustomerProcessor' => 'patron',
    'UpdateOrderStatusApprovedProcessor' => 'patron',
    'UpdateOrderStatusCanceledProcessor' => 'patron',
    'UpdateOrderStatusDeferredProcessor' => 'patron',
    'CheckOrderDateArchivingCompleteProcessor' => 'delivery',
    'CheckOrderDeliveryMethodProcessor' => 'delivery',
    'CheckOrderReadyForDeliveryProcessor' => 'delivery',
    'CheckOrderFeeProcessor' => 'delivery',
    'CreateInvoiceProcessor' => 'delivery',
    'CreatePatronDeliverablesProcessor' => 'delivery',
    'CreateOrderEmailProcessor' => 'delivery',
    'CreateOrderPdfProcessor' => 'delivery',
    'CreateOrderZipProcessor' => 'delivery',
    'CreateUnitDeliverablesProcessor' => 'delivery',
    'DeleteUnitCopyForDeliverableGenerationProcessor' => 'delivery',
    'MoveCompletedDirectoryToDeleteDirectoryProcessor' => 'delivery',
    'MoveDeliverablesToDeliveredOrdersDirectoryProcessor' => 'delivery',
    'QueueUnitDeliverablesProcessor' => 'delivery',
    'SendOrderEmailProcessor' => 'delivery',
    'UpdateOrderDateCustomerNotifiedProcessor' => 'delivery',
    'UpdateOrderDatePatronDeliverablesCompleteProcessor' => 'delivery',
    'UpdateOrderEmailDateProcessor' => 'delivery',
    'UpdateUnitDatePatronDeliverablesReadyProcessor' => 'delivery',
    'BurstPdfProcessor' => 'production',
    'CreateImageTechnicalMetadataAndThumbnailProcessor' => 'production',
    'CreateMasterFileRecordsFromTifAndTextProcessor' => 'production',
    'CreateTextFromPdfProcessor' => 'production',
    'CreateTifImagesFromPdfProcessor' => 'production',
    'SendPdfUnitToFinalizationDirProcessor' => 'production',
    'PurgeCacheProcessor' => 'administrative' 
    }

end
  
# == Schema Information
#
# Table name: automation_messages
#
#  id              :integer(4)      not null, primary key
#  pid             :string(255)
#  app             :string(255)
#  processor       :string(255)
#  message_type    :string(255)
#  message         :string(255)
#  class_name      :string(255)
#  backtrace       :text
#  created_at      :datetime
#  updated_at      :datetime
#  active_error    :boolean(1)      default(FALSE), not null
#  messagable_id   :integer(4)      not null
#  messagable_type :string(20)      not null
#  workflow_type   :string(255)
#

