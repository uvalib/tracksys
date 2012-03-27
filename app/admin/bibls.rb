ActiveAdmin.register Bibl do
  menu :priority => 5

  scope :all, :default => true
  scope :approved
  scope :not_approved

  filter :title
  filter :call_number
  filter :creator_name
  filter :catalog_key
  filter :barcode
  filter :pid
  filter :resource_type, :as => :select, :collection => Bibl.select(:resource_type).order(:resource_type).uniq.map(&:resource_type)
  filter :customers_id, :as => :numeric
  filter :orders_id, :as => :numeric

  index :id => 'bibls' do
    column :id
    column :title
    column :creator_name
    column :call_number
    column :catalog_key
    column :barcode
    column :pid
    column ("Date Ingested Into DL") {|bibl| format_date(bibl.date_dl_ingest) }
    column("Units") {|bibl| bibl.units.size.to_s }
    column("Master Files") do |bibl|
      link_to bibl.master_files_count, "master_files?q%5Bbibl_id_eq%5D=#{bibl.id}&order=filename_asc"
    end
    default_actions
  end
  
  show do
    panel "Units", :id => 'units' do
      table_for bibl.units do
        column("ID") {|u| link_to "#{u.id}", admin_unit_path(u)}
        column ("DL Status") {|unit|
          case 
            when unit.include_in_dl?
              Unit.human_attribute_name(:include_in_dl)
            when unit.exclude_from_dl?
              Unit.human_attribute_name(:exclude_from_dl)
          end
        }
        column :date_archived
        column :date_patron_deliverables_ready
        column :date_queued_for_ingest
        column :date_dl_deliverables_ready
        column :intended_use
        column :master_files_count
      end
    end

    panel "Automation Messages", :id => 'automation_messages', :toggle => 'hide' do
      table_for bibl.automation_messages do
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

  sidebar "Bibliographic Information", :id => 'bibls', :only => :show do
    attributes_table_for bibl, :title, :creator_name, :call_number, :catalog_key, :barcode, :pid
  end

  # action_item :only => :show do
  #   button_to "Update All XML Datastreams ", update_metadata_admin_bibl_url(bibl), :method => 'get'
  # end

  # controller do
  #   require 'activemessaging/processor'
  #   include ActiveMessaging::MessageSender
        
  #   publishes_to :update_fedora_datastreams

  #   def update_metadata
  #     message = ActiveSupport::JSON.encode( { :object_class => params[:object_class], :object_id => params[:object_id], :datastream => params[:datastream] })
  #     publish :update_fedora_datastreams, message
  #     flash[:notice] = "#{params[:datastream].gsub(/_/, ' ').capitalize} datastream(s) being updated."
  #     redirect_to :action => "show", :controller => "bibl", :id => params[:object_id]
  #   end
  # end

  # action_item :only => :show do
  #   button_to "Update All XML Datastreams ", update_metadata_admin_bibl_path(bibl), :method => 'get'
  # end

  # member_action :update_metadata do
  #   message = ActiveSupport::JSON.encode( { :object_class => params[:object_class], :object_id => params[:object_id], :datastream => params[:datastream] })
  #   publish :update_fedora_datastreams, message
  #   flash[:notice] = "#{params[:datastream].gsub(/_/, ' ').capitalize} datastream(s) being updated."
  #   redirect_to :action => "show", :controller => "bibl", :id => params[:object_id]
  # end
end