class CustomersSweeper < ActionController::Caching::Sweeper
  include Rails.application.routes.url_helpers 
  
  require 'activemessaging/processor'
  include ActiveMessaging::MessageSender

  observe Customer

  # The after_update callback has a second expiry method for associated classes that is not required for
  # the destroy method since there should be no records associated with a destroyed record.
  def after_update(customer)
    expire(customer)
    expire_associated(customer)
  end
  
  def after_create(customer)
    expire(customer)
    expire_associated(customer)
  end
  
  def after_destroy(customer)
    expire(customer)
  end
  
  def expire(customer)
    # Expire the index and show views for self
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_customer_path(customer.id)}")
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_customers_path}")
  end

  # Since subordinate classes often display Customer information in their views, we need only to expire those cached views.
  # The classes which display Customer information on their show views are:
  # 1. Orders
  # 2. Units
  # 3. MasterFiles
  # 4. Bibls
  # 5. Customers
  #
  # The message sent to the purge_cache_processor will do something akin to the following:
  #   customer.orders.each {|order| 
  #     order_show_cache_key = "views/tracksys.lib.virginia.edu" + "#{admin_order_path(order)}"
  #     Rails.cache.delete(order_show_cache_key) 
  #   }
  def expire_associated(customer)
    associated_classes = ['Order', 'Unit', 'MasterFile', 'Agency', 'Bibl']
    associated_classes.each {|ac|
      publish :purge_cache, ActiveSupport::JSON.encode( {:subject_class => customer.class.name, :subject_id => customer.id, :associated_class => "#{ac}" }) 
    }
  end
end
