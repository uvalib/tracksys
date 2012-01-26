class MasterFilesSweeper < ActionController::Caching::Sweeper
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
    # expire_page "/admin/master_files/#{master_file.id}"
    # expire_page "/public/admin/master_files"
    expire_action :controller => 'admin/master_files', :action => 'index'
    expire_page :controller => 'admin/master_files', :action => 'show', :id => master_file.id
    expire_fragment %r{master_files/d*}
    # expire_fragment :regexp, %r{master_files}
  end
end
