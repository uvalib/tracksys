ActiveAdmin.register Order, :namespace => :patron do

  scope :all
  scope :awaiting_approval, :defaults => true
  scope :deferred
  scope :in_process

  # collection_action :deferred do
  #   @collection = Order.deferred
  #   column(:id)
  # end
  filter :id

  index do

  end

  show do

  end

  form do

  end

  member_action :approve do
    order = Order.find(params[:id])
    message = ActiveSupport::JSON.encode( {:order_id => order.id, :workflow_type => 'patron'})
    publish :update_order_status_approved, message
    sleep 0.5 # Give DB chance to update before user views order again.
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
    publishes_to :send_fee_estimate_to_customer
  end

end