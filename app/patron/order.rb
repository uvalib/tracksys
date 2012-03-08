ActiveAdmin.register Order, :namespace => :patron do

  scope :all
  scope :awaiting_approval, :defaults => true
  scope :deferred
  scope :in_process

  filter :id

  index do

  end

  show do

  end

  form do

  end

  member_action :approve do
    order = Order.find(params[:id])
    order.update_attribute(:order_status => 'approved')
    flash[:notice] = "Order #{order.id} is now approved."
    redirect_to :action => "show", :id => params[:id]
  end

  member_action :cancel do

  end

  member_action :defer do

  end

  action_item :only => :show do
    link_to "Approve", approve_patron_order_path(order)
  end

  controller do
    require 'activemessaging/processor'
    include ActiveMessaging::MessageSender

  end

end