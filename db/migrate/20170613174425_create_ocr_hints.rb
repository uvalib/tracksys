class CreateOcrHints < ActiveRecord::Migration
   def change
      create_table :ocr_hints do |t|
         t.string :name
         t.boolean :ocr_candidate, default: true
      end

      OcrHint.create([
         {name: 'Regular Font', ocr_candidate: true},
         {name: 'Non-Text Image', ocr_candidate: false},
         {name: 'Handwritten', ocr_candidate: false},
         {name: 'Illegible', ocr_candidate: false}
      ])

      add_reference :metadata, :ocr_hint, index: true, foreign_key: true
   end
end
