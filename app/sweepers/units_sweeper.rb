class UnitsSweeper < ActionController::Caching::Sweeper
  include Rails.application.routes.url_helpers 
  observe Unit

  def after_update(unit)
    expire(unit)
  end
  
  def after_create(unit)
    expire(unit)
  end
  
  def after_destroy(unit)
    expire(unit)
  end
  
  def expire(unit)
    # Expire the index and show views for self
    show_cache_key = "views/tracksys.lib.virginia.edu" + "#{admin_unit_path(unit)}"
    index_cache_key = "views/tracksys.lib.virginia.edu" + "#{admin_units_path}"
    Rails.cache.delete(show_cache_key)
    Rails.cache.delete(index_cache_key)
  end
end
