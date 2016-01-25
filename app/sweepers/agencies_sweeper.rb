class AgenciesSweeper < ActionController::Caching::Sweeper
  observe Agency
  include Rails.application.routes.url_helpers

  # The after_update callback has a second expiry method for associated classes that is not required for
  # the destroy method since there should be no records associated with a destroyed record.
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
    # Expire the index and show views for self.  Additionally, since Agency uses the ancestry gem, we need to clear
    # the cache of self's ancestors and descendants.  Those related agencies use the name in the show view.
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_agency_path(agency.id)}")
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_agencies_path}")

    # Since Agency uses the ancestry gem, we need to clear the cache of self's ancestors and descendants.
    # Those related agencies use the name and various counts which are liable to change.
    related = []
    related << agency.ancestors
    related << agency.descendants

    related.flatten.each {|agency|
      Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_agency_path(agency.id)}")
    }

    def expire_associated(agency)
      # Subordinate classes display Agency#name so we need only to expire those cached viewsif Agency#name is a changed attribute.
      # The classes which display Agency information on their show views are: Orders, Units, MasterFiles, Bibls and Customers

      expirable = ['name'].any? do |key|
        agency.changed_attributes.include?(key)
      end

      if expirable
        associated_classes = ['Order', 'Unit', 'MasterFile', 'Bibl', 'Customer']
        associated_classes.each {|ac|
          PurgeCache.exec( {:subject_class => agency.class.name, :subject_id => agency.id, :associated_class => "#{ac}" })
        }
      end
    end
  end
end
