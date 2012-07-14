class OrdersSweeper < ActionController::Caching::Sweeper
  include Rails.application.routes.url_helpers 
  observe Order

  def after_update(order)
    expire(order)
  end
  
  def after_create(order)
    expire(order)
  end
  
  def after_destroy(order)
    expire(order)
  end
  
  def expire(order)
    # Expire the index and show views for self
    show_cache_key = "views/tracksys.lib.virginia.edu" + "#{admin_order_path(order)}"
    index_cache_key = "views/tracksys.lib.virginia.edu" + "#{admin_orders_path}"
    Rails.cache.delete(show_cache_key)
    Rails.cache.delete(index_cache_key)
  end
end
