class BiblsSweeper < ActionController::Caching::Sweeper
  include Rails.application.routes.url_helpers 
  observe Bibl

  def after_update(bibl)
    expire(bibl)
  end
  
  def after_create(bibl)
    expire(bibl)
  end
  
  def after_destroy(bibl)
    expire(bibl)
  end
  
  def expire(bibl)
    # Expire the index and show views for self
    show_cache_key = "views/tracksys.lib.virginia.edu" + "#{admin_bibl_path(bibl)}"
    index_cache_key = "views/tracksys.lib.virginia.edu" + "#{admin_bibls_path}"
    Rails.cache.delete(show_cache_key)
    Rails.cache.delete(index_cache_key)
  end
end
