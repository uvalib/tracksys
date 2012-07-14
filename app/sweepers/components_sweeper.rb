class ComponentsSweeper < ActionController::Caching::Sweeper
  include Rails.application.routes.url_helpers 

  require 'activemessaging/processor'
  include ActiveMessaging::MessageSender

  observe Component

  def after_update(component)
    expire(component)
    expire_associated(component)
  end
  
  def after_create(component)
    expire(component)
    expire_associated(component)
  end
  
  def after_destroy(component)
    expire(component)
  end
  
  def expire(component)
    # Expire the index and show views for self
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_component_path(component)}")
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_components_path}")

    # Since Agency uses the ancestry gem, we need to clear the cache of self's ancestors and descendants.  
    # Those related agencies use the name and various counts which are liable to change.
    related = []
    related << component.ancestors
    related << component.descendants
    
    related.flatten.each {|component|
      Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_component_path(component)}")
    }
  end

  def expire_associated(component)
    # Since subordinate classes only display the Component#name in their views, we need only to expire those cached views
    # if Component#name is a changed attribute.
    # The only classes which display Component#name information are:
    # 1. MasterFiles
    publish :purge_cache, ActiveSupport::JSON.encode( {:subject_class => component.class.name, :subject_id => component.id, :associated_class => "MasterFile" })
  end
end
