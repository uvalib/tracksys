ActiveAdmin.register MasterFile do

  # controller do
  #   caches_page :show
  #   caches_action :index, :cache_path => Proc.new{|c| c.params}
  #   cache_sweeper :master_files_sweeper
  # end

  menu :priority => 6

  scope :all, :default => true

  filter :filename
  filter :title
  filter :description
  filter :transcription_text
  filter :pid
  filter :unit_id, :as => :numeric, :label => "Unit ID"
  filter :order_id, :as => :numeric, :label => "Order ID"
  filter :customer_id, :as => :numeric, :label => "Customer ID"
  filter :customer_last_name, :as => :string, :label => "Customer Last Name"
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