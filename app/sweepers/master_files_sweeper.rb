class MasterFilesSweeper < ActionController::Caching::Sweeper
  include Rails.application.routes.url_helpers 
  observe MasterFile

  def after_update(master_file)
    expire(master_file)
  end
  
  def after_create(master_file)
    expire(master_file)
  end
  
  def after_destroy(master_file)
    expire(master_file)
  end
  
  def expire(master_file)
    show_cache_key = "views/tracksys.lib.virginia.edu" + "#{admin_master_file_path(master_file)}"
    index_cache_key = "views/tracksys.lib.virginia.edu" + "#{admin_master_files_path}"
    Rails.cache.delete(show_cache_key)
    Rails.cache.delete(index_cache_key)
    # app = ActionDispatch::Integration::Session.new(Rails.application)
    # app.get app.admin_master_file_path(master_file.id), {}, {'HTTP_REMOTE_USER' => 'aec6v'}

    # MasterFile records appear on Unit#show, so expire MasterFile's Unit when expiring MasterFile
    # and then immediately re-add the expired Unit back into the cache.
    UnitsSweeper.instance.expire(master_file.unit)
  end
end
