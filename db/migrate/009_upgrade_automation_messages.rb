 class UpgradeAutomationMessages < ActiveRecord::Migration
  def change
    change_table(:automation_messages, :bulk => true) do |t|
      t.integer :messagable_id, :null => false
      t.string :messagable_type, :null => false, :limit => 20

      t.string :workflow_type
      t.index :workflow_type
      t.change :active_error, :boolean, :null => false, :default => 0
      t.change :message, :string
      t.remove :ead_ref_id
    end

    # Transition all legacy *_id to messagable_id and messagable_type
    AutomationMessage.where('bibl_id is not null').find_each(:batch_size => 50000) do |am|
      am.update_attribute(:messagable_type, "Bibl")
      am.update_attribute(:messagable_id, am.bibl_id)
    end

    AutomationMessage.where('order_id is not null').find_each(:batch_size => 50000) do |am|
      am.update_attribute(:messagable_type, "Order")
      am.update_attribute(:messagable_id, am.order_id)
    end

    AutomationMessage.where('component_id is not null').find_each(:batch_size => 50000) do |am|
      am.update_attribute(:messagable_type, "Component")
      am.update_attribute(:messagable_id, am.component_id)
    end

    AutomationMessage.where('master_file_id is not null').find_each(:batch_size => 50000) do |am|
      am.update_attribute(:messagable_type, "MasterFile")
      am.update_attribute(:messagable_id, am.master_file_id)
    end

    AutomationMessage.where('unit_id is not null').find_each(:batch_size => 50000) do |am|
      am.update_attribute(:messagable_type, "Unit")
      am.update_attribute(:messagable_id, am.unit_id)
    end

    AutomationMessage.where('bibl_id is not null').update_all( :bibl_id => nil )
    AutomationMessage.where('order_id is not null').update_all( :order_id => nil )
    AutomationMessage.where('component_id is not null').update_all( :component_id => nil )
    AutomationMessage.where('master_file_id is not null').update_all( :master_file_id => nil )
    AutomationMessage.where('unit_id is not null').update_all( :unit_id => nil )

    change_table(:automation_messages, :bulk => true) do |t|
      t.remove :bibl_id
      t.remove :unit_id
      t.remove :master_file_id
      t.remove :order_id
      t.remove :component_id
    end

    # Update all AutomationMessages so that each message has a workflow_type appropriate to its processor
    administrative = %w[CreateStatsReportProcessor]

    administrative.each {|processor|
      AutomationMessage.where(:processor => processor).update_all :workflow_type => 'administrative'
    }

    archive = %w[SendUnitToArchiveProcessor 
    StartManualUploadToArchiveMigrationProcessor 
    StartManualUploadToArchiveProcessor 
    StartManualUploadToArchiveProductionProcessor 
    UpdateOrderDateArchivingCompleteProcessor 
    UpdateUnitArchiveIdProcessor 
    UpdateUnitDateArchivedProcessor]

    archive.each {|processor|
      AutomationMessage.where(:processor => processor).update_all :workflow_type => 'archive'
    }

    repository = %w[CreateDlDeliverablesProcessor
    CreateNewFedoraObjectsProcessor
    IngestDcMetadataProcessor
    IngestDescMetadataProcessor
    IngestJp2kProcessor
    IngestMarcProcessor
    IngestRelsExtProcessor
    IngestRelsIntProcessor
    IngestRightsMetadataProcessor
    IngestSolrDocProcessor
    IngestTechMetadataProcessor
    IngestTranscriptionProcessor
    PropogateAccessPoliciesProcessor
    PropogateDiscoverabilityProcessor
    PropogateIndexingScenariosProcessor
    QueueObjectsForFedoraProcessor
    SendCommitToSolrProcessor 
    StartIngestFromArchiveProcessor 
    UpdateFedoraDatastreamsProcessor 
    UpdateUnitDateDlDeliverablesReadyProcessor 
    UpdateUnitDateQueuedForIngestProcessor]

    repository.each {|processor|
      AutomationMessage.where(:processor => processor).update_all :workflow_type => 'repository'
    }

    qa = %w[CheckUnitDeliveryModeProcessor
    CopyMetadataToMetadataDirectoryProcessor
    ImportUnitIviewXMLProcessor
    QaFilesystemAndIviewXmlProcessor
    QaOrderDataProcessor
    QaUnitDataProcessor
    StartFinalizationMigrationProcessor 
    StartFinalizationProcessor 
    StartFinalizationProductionProcessor 
    UpdateOrderDateFinalizationBegunProcessor]

    qa.each {|processor|
      AutomationMessage.where(:processor => processor).update_all :workflow_type => 'qa'
    }

    patron = %w[CopyArchivedFilesToProductionProcessor
    CopyDirectoryFromArchiveProcessor
    SendFeeEstimateToCustomerProcessor 
    UpdateOrderDateFeeEstimateSentToCustomerProcessor 
    UpdateOrderStatusApprovedProcessor 
    UpdateOrderStatusCanceledProcessor 
    UpdateOrderStatusDeferredProcessor]

    patron.each {|processor|
      AutomationMessage.where(:processor => processor).update_all :workflow_type => 'patron'
    }

    delivery = %w[CheckOrderDateArchivingCompleteProcessor
    CheckOrderDeliveryMethodProcessor
    CheckOrderReadyForDeliveryProcessor
    CheckOrderFeeProcessor
    CreateInvoiceProcessor
    CreatePatronDeliverablesProcessor
    CreateOrderEmailProcessor
    CreateOrderPdfProcessor
    CreateOrderZipProcessor
    CreateUnitDeliverablesProcessor
    DeleteUnitCopyForDeliverableGenerationProcessor
    MoveCompletedDirectoryToDeleteDirectoryProcessor
    MoveDeliverablesToDeliveredOrdersDirectoryProcessor
    QueueUnitDeliverablesProcessor
    SendOrderEmailProcessor 
    UpdateOrderDateCustomerNotifiedProcessor
    UpdateOrderDatePatronDeliverablesCompleteProcessor
    UpdateOrderEmailDateProcessor
    UpdateUnitDatePatronDeliverablesReadyProcessor]

    delivery.each {|processor|
      AutomationMessage.where(:processor => processor).update_all :workflow_type => 'delivery'
    }

    production = %w[BurstPdfProcessor
    CreateImageTechnicalMetadataAndThumbnailProcessor
    CreateMasterFileRecordsFromTifAndTextProcessor
    CreateTextFromPdfProcessor
    CreateTifImagesFromPdfProcessor
    SendPdfUnitToFinalizationDirProcessor]

    production.each {|processor|
      AutomationMessage.where(:processor => processor).update_all :workflow_type => 'production'
    }

  end
end
