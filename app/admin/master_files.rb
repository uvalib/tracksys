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

  show do
    table do
      tr do
        td do
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
        td do
          panel "Digital Library Information" do
            attributes_table_for master_file do
              row :pid
              row :availability
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
        td do
          panel "Thumbnail" do
            div do
              image_tag("#{master_file.link_to_thumbnail}", :height => "300", :alt => "#{master_file.title}")
            end
          end
        end
      end
      tr do
        td do
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
        td do
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
      end
    end

    panel "Units" do
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
  end


  action_item :only => :show do
    link_to_unless(master_file.previous.nil?, "Previous", admin_master_file_path(master_file.previous))
  end

  action_item :only => :show do
    link_to_unless(master_file.next.nil?, "Next", admin_master_file_path(master_file.next))
  end


  # sidebar "Test" do
  #   div :class => 'action_items' do
  #     span :class => 'action_item' do
  #       link_to_unless(master_file.previous.nil?, "Previous", admin_master_file_path(master_file.previous))
  #     end
  #     span :class => 'action_item' do 
  #       link_to_unless(master_file.next.nil?, "Next", admin_master_file_path(master_file.next))
  #     end
  #   end
  # end
end