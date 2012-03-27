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
  filter :customer_last_name, :as => :string, :label => "Customer Last Name"
  filter :bibl_call_number, :as => :string, :label => "Call Number"
  filter :bibl_barcode, :as => :string, :label => "Barcode"
  filter :bibl_catalog_key, :as => :string, :label => "Catalog Key"
  filter :academic_status, :as => :select
  
  index do
    column :filename
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
    column :pid
    column("") do |mf|
      div :class => 'index_links' do
        links = "".html_safe
        if mf.date_dl_ingest
          links += link_to "Fedora", "#{FEDORA_REST_URL}/objects/#{mf.pid}", :class => 'member_link', :target => "_blank"
        end
        if mf.date_archived
          links += link_to "Download", copy_from_archive_admin_master_file_path(mf), :class => 'member_link', :method => 'get'
        end
        links += link_to I18n.t('active_admin.view'), resource_path(mf), :class => "member_link view_link"
        links += link_to I18n.t('active_admin.edit'), edit_resource_path(mf), :class => "member_link edit_link"
        links
      end
    end
  end

  show do
    div :class => 'two-column' do
      div :class => 'master_file_thumbnail_show' do
        image_tag("#{master_file.link_to_thumbnail}", :alt => "#{master_file.title}")
      end
    end

    div :class => 'two-column' do
      panel "Basic Information" do
        attributes_table_for master_file do
          row :filename
          row :title
          row :description
          row :filesize
          row :tech_meta_type
          row :md5
          row :date_archived
          row :transcription_text
        end
      end
    end

    div :class => 'three-column' do
      panel "Digital Library Information" do
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
        end
      end
    end

    div :class => 'three-column' do
      panel "Technical Information" do 
        if master_file.image_tech_meta
          attributes_table_for master_file.image_tech_meta do
            row :image_format
            row("Height x Width"){|mf| "#{mf.height} x #{mf.width}"}
            row :color_space
            row :color_profile
            row :equipment
          end
        else
          "No technical metadata available."
        end
      end
    end

    div :class => 'three-column' do
      panel "Static Digital Library Metadata" do
        attributes_table_for master_file do
          row(:desc_metadata) {|master_file| truncate_words(master_file.desc_metadata)}
          row(:solr) {|master_file| truncate_words(master_file.solr)}
          row(:dc) {|master_file| truncate_words(master_file.dc)}
          row(:rels_ext) {|master_file| truncate_words(master_file.rels_ext)}
          row(:rels_int) {|master_file| truncate_words(master_file.rels_int)}
        end
      end
    end

    div :class => 'columns-none' do
      panel "Unit" do
        table_for Array(master_file.unit) do
          column("ID") {|unit| link_to "#{unit.id}", admin_unit_path(unit) }
          column :order, :sortable => false
          column :unit_status, :sortable => false
          column :bibl, :sortable => false
          column :bibl_call_number, :sortable => false
          column :date_archived do |unit|
            format_date(unit.date_archived)
          end
          column :date_dl_deliverables_ready do |unit|
            format_date(unit.date_dl_deliverables_ready)
          end
          column("# of Master Files") {|unit| unit.master_files_count.to_s}
        end
      end

      panel "Automation Messages" do
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

      panel "Components" do
        table_for Array(master_file.component) do
          column("ID") {|c| link_to "{c.id}", admin_component_path(c)}
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

  member_action :copy_from_archive

  controller do
    require 'activemessaging/processor'
    include ActiveMessaging::MessageSender

    publishes_to :copy_archived_files_to_production
    
    def scoped_collection
      end_of_association_chain.index_scope
    end

    def copy_from_archive
      master_file = MasterFile.find(params[:id])
      message = ActiveSupport::JSON.encode( { :unit_id => master_file.unit_id, :master_file_filename => master_file.filename, :computing_id => 'aec6v' })
      publish :copy_archived_files_to_production, message
      flash[:notice] = "The file #{master_file.filename} is now being downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR}."
      redirect_to :back
    end
  end
end
