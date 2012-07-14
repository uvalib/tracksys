class AgenciesSweeper < ActionController::Caching::Sweeper
  include Rails.application.routes.url_helpers 

  require 'activemessaging/processor'
  include ActiveMessaging::MessageSender

  observe Agency

  def after_update(agency)
    expire(agency)
    expire_associated(agency)
  end
  
  def after_create(agency)
    expire(agency)
    expire_associated(agency)
  end
  
  def after_destroy(agency)
    expire(agency)
  end
  
  def expire(agency)
    # Expire the index and show views for self
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_agency_path(agency)}")
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_agencies_path}")

    # Since Agency uses the ancestry gem, we need to clear the cache of self's ancestors and descendants.  
    # Those related agencies use the name and various counts which are liable to change.
    related = []
    related << agency.ancestors
    related << agency.descendants
    
    related.flatten.each {|agency|
      Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_agencies_path}")
    }

    def expire_associated(agency)
      # Since subordinate classes only display the Agency#name in their views, we need only to expire those cached views
      # if Agency#name is a changed attribute.
      # The only classes which display Agency#name information are:
      # 1. Orders
      # 2. Units
      # 3. MasterFiles
      # 4. Bibls
      # 5. Customers
      associated_classes = ['Order', 'Unit', 'MasterFile', 'Bibl', 'Customer']
      associated_classes.each {|ac|
        publish :purge_cache, ActiveSupport::JSON.encode( {:subject_class => agency.class.name, :subject_id => agency.id, :associated_class => "#{ac}" }) 
      }
    end
  end
end
