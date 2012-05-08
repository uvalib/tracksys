ActiveAdmin.register MasterFile do
  config.sort_order = 'filename_asc'

  menu :priority => 6

  scope :all, :show_count => false, :default => true
  scope :in_digital_library, :show_count => false
  scope :not_in_digital_library, :show_count => false
  
  actions :all, :except => [:new, :destroy]

  batch_action :download_from_archive do |selection|
    selection.each {|s| MasterFile.find(s).get_from_stornext }
    flash[:notice] = "Master Files #{selection.join(", ")} are now being downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR}."
    redirect_to :back
  end

  filter :id
  filter :filename
  filter :title
  filter :description
  filter :transcription_text
  filter :pid
  filter :unit_id, :as => :numeric, :label => "Unit ID"
  filter :order_id, :as => :numeric, :label => "Order ID"
  filter :customer_id, :as => :numeric, :label => "Customer ID"
  filter :bibl_id, :as => :numeric, :label => "Bibl ID"
  filter :customer_last_name, :as => :string, :label => "Customer Last Name"
  filter :bibl_title, :as => :string, :label => "Bibl Title"
  filter :bibl_creator_name, :as => :string, :label => "Author"
  filter :bibl_call_number, :as => :string, :label => "Call Number"
  filter :bibl_barcode, :as => :string, :label => "Barcode"
  filter :bibl_catalog_key, :as => :string, :label => "Catalog Key"
  filter :academic_status, :as => :select
  filter :availability_policy
  filter :indexing_scenario
  filter :date_archived
  filter :date_dl_ingest
  filter :date_dl_update
  filter :agency, :as => :select
  filter :archive, :as => :select
  filter :heard_about_service, :as => :select
  filter :heard_about_resource, :as => :select
  
  index :id => 'master_files' do
    selectable_column
    column :filename, :sortable => false
    column :title do |mf|
      truncate_words(mf.title)
    end
    column :description do |mf|
      truncate_words(mf.description)
    end
    column :date_archived do |mf|
      format_date(mf.date_archived)
    end
    column :date_dl_ingest do |mf|
      format_date(mf.date_dl_ingest)
    end
    column :pid, :sortable => false
    column ("Bibliographic Title") do |mf|
      link_to "#{mf.bibl_title}", admin_bibl_path(mf.bibl.id)
    end
    column("Thumbnail") do |mf|
      link_to image_tag(mf.link_to_static_thumbnail, :height => 125), "#{mf.link_to_static_thumbnail}", :rel => 'colorbox', :title => "#{mf.filename} (#{mf.title} #{mf.description})"
    end
    column("") do |mf|
      div do
        link_to "Details", resource_path(mf), :class => "member_link view_link"
      end
      div do
        link_to I18n.t('active_admin.edit'), edit_resource_path(mf), :class => "member_link edit_link"
      end
      if mf.in_dl?
        div do
          link_to "Fedora", "#{FEDORA_REST_URL}/objects/#{mf.pid}", :class => 'member_link', :target => "_blank"
        end
      end
      if mf.date_archived
        div do
          link_to "Download", copy_from_archive_admin_master_file_path(mf.id), :method => :put
        end
      end
    end
  end

  show do
    div :class => 'two-column' do
      panel "General Information" do
        attributes_table_for master_file do
          row :filename
          row :title
          row :description
          row :date_archived do |master_file|
            format_date(master_file.date_archived)
          end
          row :transcription_text
        end
      end
    end

    div :class => 'two-column' do
      panel "Technical Information", :id => 'master_files' do 
        attributes_table_for master_file do
          row :md5
          row :filesize
          row :equipment do |master_file|
            master_file.image_tech_meta.equipment
          end
          row :image_format do |master_file|
            master_file.image_tech_meta.image_format
          end
        end
        if master_file.image_tech_meta
          attributes_table_for master_file.image_tech_meta do
            row :image_format
            row("Height x Width"){|mf| "#{mf.height} x #{mf.width}"}
            row :color_space
            row :color_profile
            row :equipment
            # row :filesize
            # row :tech_meta_type
            # row :md5
          end
        else
          "No technical metadata available."
        end
      end
    end

    div :class => 'columns-none', :toggle => 'hide' do
      panel "Digital Library Information", :id => 'master_files', :toggle => 'hide' do
        attributes_table_for master_file do
          row :pid
          row :availability_policy
          row :indexing_scenario
          row :discoverability do |mf|
            case mf.discoverability
            when false
              "Not uniquely discoverable"
            when true
              "Uniquely discoverable"
            else
              "Unknown"
            end
          end
          row(:desc_metadata) {|master_file| truncate_words(master_file.desc_metadata)}
          row(:solr) {|master_file| truncate_words(master_file.solr)}
          row(:dc) {|master_file| truncate_words(master_file.dc)}
          row(:rels_ext) {|master_file| truncate_words(master_file.rels_ext)}
          row(:rels_int) {|master_file| truncate_words(master_file.rels_int)}
        end
      end
    end

    
  end

  form do |f|
    f.inputs "General Information", :class => 'panel three-column ' do
      f.input :filename
      f.input :title
      f.input :description
      f.input :date_archived, :as => :string, :input_html => {:class => :datepicker}
      f.input :transcription_text, :input_html => { :rows => 5 }
    end

    f.inputs "Technical Information", :class => 'three-column panel' do
      f.input :md5, :input_html => { :disabled => true }
      f.input :filesize, :as => :string
    end

    f.inputs "Related Information", :class => 'panel three-column' do
      f.input :unit_id, :as => :string
    end

    f.inputs "Digital Library Information", :class => 'panel columns-none', :toggle => 'hide' do
      f.input :pid, :input_html => { :disabled => true }
      f.input :availability_policy
      f.input :indexing_scenario
      f.input :desc_metadata, :input_html => { :rows => 5 }
      f.input :solr, :input_html => { :rows => 5 }
      f.input :dc, :input_html => { :rows => 5 }
      f.input :rels_ext, :input_html => { :rows => 5 }
      f.input :rels_int, :input_html => { :rows => 5 }
    end

    f.inputs :class => 'columns-none' do
      f.actions
    end
  end

  sidebar "Thumbnail", :only => [:show] do
    link_to image_tag(master_file.link_to_static_thumbnail, :height => 250), "#{master_file.link_to_static_thumbnail}", :rel => 'colorbox', :title => "#{master_file.filename} (#{master_file.title} #{master_file.description})"
  end

  sidebar "Related Information", :only => [:show] do
    attributes_table_for master_file do
      row :unit do |master_file|
        link_to "##{master_file.unit.id}", admin_unit_path(master_file.unit.id)
      end
      row :bibl
      row :order do |master_file|
        link_to "##{master_file.order.id}", admin_order_path(master_file.order.id)
      end
      row :customer
      row :component
      row :automation_messages do |master_file|
        link_to "#{master_file.automation_messages_count}", admin_automation_messages_path(:q => {:messagable_id_eq => master_file.id, :messagable_type_eq => "MasterFile" })
      end
      row :agency
    end
  end

  action_item :only => :show do
    link_to_unless(master_file.previous.nil?, "Previous", admin_master_file_path(master_file.previous))
  end

  action_item :only => :show do
    link_to_unless(master_file.next.nil?, "Next", admin_master_file_path(master_file.next))
  end

  action_item :only => :show do 
    if master_file.in_dl?
      if master_file.discoverability
        link_to "Pin It", "http://pinterest.com/pin/create/button/?#{URI.encode_www_form("url" => "http://search.lib.virginia.edu/catalog/#{master_file.pid}/view", "media" => "http://fedoraproxy.lib.virginia.edu/fedora/get/#{master_file.pid}/djatoka:jp2SDef/getRegion?scale=800", "description" => "#{master_file.title} from #{master_file.bibl_title} &#183; #{master_file.bibl_creator_name} &#183; #{master_file.bibl.year} &#183; Albert and Shirley Small Special Collections Library, University of Virginia.")}", :class => "pin-it-button", :'count-layout' => 'vertical'
      else
        link_to "Pin It", "http://pinterest.com/pin/create/button/?#{URI.encode_www_form("url" => "http://search.lib.virginia.edu/catalog/#{master_file.bibl.pid}/view?&page=#{master_file.pid}", "media" => "http://fedoraproxy.lib.virginia.edu/fedora/get/#{master_file.pid}/djatoka:jp2SDef/getRegion?scale=800", "description" => "#{master_file.title} from #{master_file.bibl_title} &#183; #{master_file.bibl_creator_name} &#183; #{master_file.bibl.year} &#183; Albert and Shirley Small Special Collections Library, University of Virginia.")}", :class => "pin-it-button", :'count-layout' => 'vertical'
      end
    else
    end
  end

  action_item :only => :show do 
    if master_file.in_dl?
      if master_file.discoverability
        tweet_button(:via => 'UVaDigServ', :url => "http://search.lib.virginia.edu/catalog/#{master_file.pid}", :text => truncate("#{master_file.bibl_title}", :length => 80), :count => 'vertical')
      else
        tweet_button(:via => 'UVaDigServ', :url => "http://search.lib.virginia.edu/catalog/#{master_file.bibl.pid}/view?&page=#{master_file.pid}", :text => truncate("#{master_file.title} from #{master_file.bibl_title}", :length => 80), :count => 'vertical')
      end
    else
    end
  end

  member_action :copy_from_archive, :method => :put do 
    mf = MasterFile.find(params[:id])
    mf.get_from_stornext
    redirect_to :back, :notice => "Master File #{params[:id]} is now being downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR}."
  end

#  controller do
#    require 'activemessaging/processor'
#    include ActiveMessaging::MessageSender

#    publishes_to :copy_archived_files_to_production

#    def copy_from_archive
#      master_file = MasterFile.find(params[:id])
#      message = ActiveSupport::JSON.encode( {:workflow_type => 'patron', :unit_id => master_file.unit_id, :master_file_filename => master_file.filename, :computing_id => 'aec6v' })
#      publish :copy_archived_files_to_production, message
#      flash[:notice] = "The file #{master_file.filename} is now being downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR}."
#      redirect_to :back
#    end
#  end
end
