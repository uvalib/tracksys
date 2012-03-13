ActiveAdmin.register Unit, :namespace => :patron do

  filter :id

  index do

  end

  show do

  end

  form do

  end
  
  sidebar :approval_workflow, :only => [:show] do
    div :class => 'workflow_button' do
      button_to "Approve", change_status_order_patron_order_path(order), :disabled => disabled, :method => 'get'
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
    include ActiveMessaging::MessageSender

    def change_status
      message = ActiveSupport::JSON.encode( { :unit_id => params[:id] :unit_status => params[:unit_status] })
      publish :update_unit_status, message
      flash[:notice] = "Unit #{params[:id]} status has been changed to #{params[:unit_status]}"
      redirect_to :back      
    end
  end

end