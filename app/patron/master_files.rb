ActiveAdmin.register MasterFile, :namespace => :patron do

  filter :bibl_id, :as => :numeric, :label => "Bibl"
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
  
  index :as => :grid, :columns => 3 do |master_file|
    div do
      link_to(image_tag("#{master_file.link_to_thumbnail}", :width => "250", :alt => "#{master_file.title}"), patron_master_file_path(master_file))
    end
#    a truncate(master_file.title), :href => patron_master_file_path(master_file)
    div do
      "Filename:  #{master_file.filename}"
    end
    div do
      "Title: #{truncate(master_file.title)}"
    end
    div do
      "Description: #{truncate(master_file.description)}" if master_file.description?
    end
  end

end
