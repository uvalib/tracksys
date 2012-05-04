ActiveAdmin.register Unit, :namespace => :patron do
  menu :priority => 4

  batch_action :destroy, false
  batch_action :print_routing_slips do |selection|

  end

  scope :all, :default => true

  filter :id
  filter :date_archived
  filter :date_dl_deliverables_ready
  filter :date_queued_for_ingest
  filter :include_in_dl, :as => :select
  # filter :exclude_from_dl, :as => :radio
  filter :bibl_call_number, :as => :string, :label => "Call Number"
  filter :bibl_title, :as => :string, :label => "Bibl. Title"
  filter :indexing_scenario
  filter :order_id, :as => :numeric, :label => "Order ID"
  filter :customer_id, :as => :numeric, :label => "Customer ID"
  
  index do
    selectable_column
    column :id
    column :bibl
    column ("DL Status") {|unit|
      case 
        when unit.include_in_dl?
          Unit.human_attribute_name(:include_in_dl)
        when unit.exclude_from_dl?
          Unit.human_attribute_name(:exclude_from_dl)
      end
    }
    column :date_archived do |unit|
      format_date(unit.date_archived)
    end
    column :date_queued_for_ingest do |unit|
      format_date(unit.date_queued_for_ingest)
    end
    column :date_dl_deliverables_ready do |unit|
      format_date(unit.date_dl_deliverables_ready)
    end
    column :intended_use
    column("Master Files") do |unit| 
      link_to unit.master_files_count, "master_files?q%5Bunit_id_eq%5D=#{unit.id}&order=filename_asc"
    end
    default_actions
  end

  show do

  end

  form do

  end
  
  sidebar :approval_workflow, :only => [:show] do
    div :class => 'workflow_button' do
      button_to "Approve", change_status_order_patron_order_path(order), :disabled => disabled, :method => 'get'
    end
    div :class => 'workflow_button' do
      button_to "Cancel", change_status_order_patron_order_path(order), :disabled => disabled, :method => 'get'
    end
    div :class => 'workflow_button' do 
      button_to "Send to Copyright Approval", change_status_order_patron_order_path(order), :disabled => disabled, :method => 'get'
    end
    div :class => 'workflow_button' do
      button_to "Send to Condition Approval", change_status_order_patron_order_path(order), :disabled => disabled, :method => 'get'
    end
  end

  member_action :change_status

  controller do
    require 'activemessaging/processor'
    include ActiveMessaging::MessageSender

    def change_status
      message = ActiveSupport::JSON.encode( { :unit_id => params[:id], :unit_status => params[:unit_status] })
      publish :update_unit_status, message
      flash[:notice] = "Unit #{params[:id]} status has been changed to #{params[:unit_status]}"
      redirect_to :back      
    end
  end
end