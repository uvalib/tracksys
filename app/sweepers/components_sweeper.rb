class ComponentsSweeper < ActionController::Caching::Sweeper
  observe Component

  require 'activemessaging/processor'
  include ActiveMessaging::MessageSender
  include Rails.application.routes.url_helpers 

  # The after_update callback has a second expiry method for associated classes that is not required for
  # the destroy method since there should be no records associated with a destroyed record.
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

  # Expire the index and show views for self.  Additionally, since the Component class uses the ancestry gem, we need to clear 
  # the cache of self's ancestors and descendants.  Those related components use the name in the show view.
  def expire(component)
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_component_path(component.id)}")
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_components_path}")

    related = []
    related << component.ancestors
    related << component.descendants
    
    related.flatten.each {|component|
      Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_component_path(component.id)}")
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
