ActiveAdmin.register MasterFile do
  menu :priority => 6

  scope :all, :default => true

  filter :unit_id, :as => :numeric, :label => "Unit"
  filter :order_id, :as => :numeric, :label => "Order"
  filter :filename
  filter :title
  filter :description
  filter :transcription_text
  filter :pid
  filter :bibl_call_number, :as => :string, :label => "Call Number"
  filter :bibl_barcode, :as => :string, :label => "Barcode"
  filter :bibl_catalog_id, :as => :string, :label => "Catalog Key"

  index do
    column :id
    column :filename
    column :title do |mf|
      truncate_words(mf.title)
    end
    column :description do |mf|
      truncate_words(mf.description)
    end
    column("Transcription") do |mf|
      truncate_words(mf.transcription_text)
    end
    column :pid
    default_actions
  end
end