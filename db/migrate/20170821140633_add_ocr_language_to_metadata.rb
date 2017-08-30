class AddOcrLanguageToMetadata < ActiveRecord::Migration[5.1]
  def change
     add_column :metadata, :ocr_language_hint, :string
  end
end
