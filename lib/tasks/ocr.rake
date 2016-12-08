namespace :ocr do
   desc "Udate text source fields for all MF wih text content. Default to Transcriotion"
   task :set_text_source  => :environment do
      q = "update master_files set text_source=2 where transcription_text is not null and transcription_text <> '' and text_source is null"
      MasterFile.connection.execute(q)
   end
end
