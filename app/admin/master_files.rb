ActiveAdmin.register MasterFile do
  config.sort_order = 'id_asc'

  menu :priority => 6
  scope :all, :default => true
  actions :all, :except => [:destroy]

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
  
  index :id => 'master_files' do
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
    column("Thumbnail") do |mf|
      if mf.in_dl?
        image_tag("http://fedoraproxy.lib.virginia.edu/fedora/get/#{mf.pid}/djatoka:jp2SDef/getRegion?scale=125", :height => '100')
      end
    end
    column ("Social Media") do |mf|
      if mf.in_dl?
        if mf.discoverability
          div do
            tweet_button(:via => 'UVaDigServ', :url => "http://search.lib.virginia.edu/catalog/#{mf.pid}", :text => truncate("#{mf.bibl_title}", :length => 80), :count => 'horizontal')
          end
          div do
            link_to "Pin It", "http://pinterest.com/pin/create/button/?#{URI.encode_www_form("url" => "http://search.lib.virginia.edu/catalog/#{mf.pid}/view", "media" => "http://fedoraproxy.lib.virginia.edu/fedora/get/#{mf.pid}/djatoka:jp2SDef/getRegion?scale=800", "description" => "#{mf.title} from #{mf.bibl_title} &#183; #{mf.bibl_creator_name} &#183; #{mf.bibl.year} &#183; Albert and Shirley Small Special Collections Library, University of Virginia.")}", :class => "pin-it-button"
          end
        else
          div do
            tweet_button(:via => 'UVaDigServ', :url => "http://search.lib.virginia.edu/catalog/#{mf.bibl.pid}/view?&page=#{mf.pid}", :text => truncate("#{mf.title} from #{mf.bibl_title}", :length => 80), :count => 'horizontal')
          end
          div do
            link_to "Pin It", "http://pinterest.com/pin/create/button/?#{URI.encode_www_form("url" => "http://search.lib.virginia.edu/catalog/#{mf.bibl.pid}/view?&page=#{mf.pid}", "media" => "http://fedoraproxy.lib.virginia.edu/fedora/get/#{mf.pid}/djatoka:jp2SDef/getRegion?scale=800", "description" => "#{mf.title} from #{mf.bibl_title} &#183; #{mf.bibl_creator_name} &#183; #{mf.bibl.year} &#183; Albert and Shirley Small Special Collections Library, University of Virginia.")}", :class => "pin-it-button"
          end
        end
      else
      end
    end
    
    column("Links") do |mf|
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
          link_to "Download", copy_from_archive_admin_master_file_path(mf), :class => 'member_link', :method => 'get'
        end
      end
    end
  end

  show do
    div :class => 'two-column' do
      panel "Basic Information", :id => 'master_files' do
        attributes_table_for master_file do
          row :filename
          row :title
          row :description
          row :bibl_call_number 
          row :date_archived
          row :transcription_text
        end
      end

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

      panel "Technical Information", :id => 'master_files', :toggle => 'hide' do 
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

    div :class => 'two-column' do
      div :class => 'master_file_thumbnail_show' do
        image_tag("#{master_file.link_to_thumbnail}", :alt => "#{master_file.title}", :height => 500)
      end
    end

    div :class => 'columns-none' do
      panel "Bbiliographic Information", :id => 'bibls', :toggle => 'hide' do
        attributes_table_for master_file.bibl do
          row :id
          row :call_number
          row :title
        end
      end


      panel "Components (#{format_boolean_as_present(master_file.component.present?)})", :id => 'components', :toggle => 'hide' do
        if master_file.component.present?
          attributes_table_for master_file.component do 
            row("ID") {|component| link_to "#{component.id}", admin_component_path(component)}
          end
        end
      end

      panel "Customer", :id => 'customers', :toggle => 'hide' do
        attributes_table_for master_file.customer do 
          row("ID") {|customer| link_to "#{customer.id}", admin_customer_path(customer)}
          row :full_name
          row :email
          row :academic_status
        end
      end

      panel "Unit", :id => 'units', :toggle => 'hide' do
        attributes_table_for master_file.unit do
          row("ID") {|unit| link_to "#{unit.id}", admin_unit_path(unit) }
          row :order
          row :unit_status
          row :bibl
          row :bibl_call_number
          row :date_archived do |unit|
            format_date(unit.date_archived)
          end
          row :date_dl_deliverables_ready do |unit|
            format_date(unit.date_dl_deliverables_ready)
          end
          row("# of Master Files") {|unit| unit.master_files_count.to_s}
        end
      end

      panel "Automation Messages (#{master_file.automation_messages_count})", :id => 'automation_messages', :toggle => 'hide' do
        table_for master_file.automation_messages do
          column("ID") {|am| link_to "#{am.id}", admin_automation_message_path(am)}
          column :message_type
          column :active_error
          column :workflow_type
          column(:message) {|am| truncate_words(am.message)}
          column(:created_at) {|am| format_date(am.created_at)}
          column("Sent By") {|am| "#{am.app.capitalize}, #{am.processor}"}
        end
      end
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
        link_to "Pin It", "http://pinterest.com/pin/create/button/?#{URI.encode_www_form("url" => "http://search.lib.virginia.edu/catalog/#{master_file.pid}/view", "media" => "http://fedoraproxy.lib.virginia.edu/fedora/get/#{mf.pid}/djatoka:jp2SDef/getRegion?scale=800", "description" => "#{master_file.title} from #{master_file.bibl_title} &#183; #{master_file.bibl_creator_name} &#183; #{master_file.bibl.year} &#183; Albert and Shirley Small Special Collections Library, University of Virginia.")}", :class => "pin-it-button", :'count-layout' => 'vertical'
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
