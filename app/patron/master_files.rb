ActiveAdmin.register MasterFile, :namespace => :patron do

  filter :title
  filter :filename
  filter :description
  filter :transcription_text
  filter :pid
  filter :bibl_title, :as => :string, :label => "Bibl Title"
  filter :bibl_call_number, :as => :string, :label => "Call Number"
  filter :bibl_barcode, :as => :string, :label => "Barcode"
  filter :bibl_catalog_key, :as => :string, :label => "Catalog Key"
  filter :bibl_id, :as => :numeric, :label => "Bibl"
  filter :unit_id, :as => :numeric, :label => "Unit"
  filter :order_id, :as => :numeric, :label => "Order"

  index :as => :block do |master_file|
    table do
      tr do
        td do
          panel "Master File #{master_file.id}" do
            table do
              tr do
                td do
                  attributes_table_for master_file do
                    row :title
                    row :description if master_file.description?
                    row :transcription_text
                    row :filename
                    row (:bibl_call_number) {|master_file| link_to "#{master_file.bibl_call_number}", patron_bibl_path(master_file.bibl)}
                    row :bibl_title
                    row :bibl_creator_name
                    row (:unit_id) {|master_file| link_to "#{master_file.unit_id}", patron_unit_path(master_file.unit)}
                    row (:customer_full_name) {|master_file| link_to "#{master_file.customer_full_name}", patron_customer_path(master_file.customer)}
                  end
                end
                td do
                  link_to(image_tag("#{master_file.link_to_thumbnail}", :height => '50%', :alt => "#{master_file.title}"), patron_master_file_path(master_file))
                end
              end
            end
            table :style => 'width:200px' do
              tr do
                td do 
                  button_to "View", patron_master_file_path(master_file), :method => 'get'
                end
                td do
                  button_to "Download", copy_from_archive_patron_master_file_path(master_file), :method => 'get'
                end
              end
            end
          end
        end
      end
    end
  end

  show do
    image_tag("#{master_file.link_to_thumbnail}", :height => "350", :alt => "#{master_file.title}")
  end

  member_action :copy_from_archive

  controller do
    require 'activemessaging/processor'
    include ActiveMessaging::MessageSender

    publishes_to :copy_archived_files_to_production

    def copy_from_archive
      master_file = MasterFile.find(params[:id])
      message = ActiveSupport::JSON.encode( { :unit_id => master_file.unit_id, :master_file_filename => master_file.filename, :computing_id => 'aec6v' })
      publish :copy_archived_files_to_production, message
      flash[:notice] = "The file #{master_file.filename} is now being downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR}."
      redirect_to :back
    end
  end
end
