ActiveAdmin.register Unit, :namespace => :patron do

  filter :id

  index do

  end

  show do

  end

  form do

  end

  controller do
  member_action :change_status

  controller do
    include ActiveMessaging::MessageSender

      message = ActiveSupport::JSON.encode( { :unit_id => params[:id] :unit_status => params[:unit_status] })
      publish :update_unit_status, message
      flash[:notice] = "Unit #{params[:id]} status has been changed to #{params[:unit_status]}"
      redirect_to :back      
    end
  end

end