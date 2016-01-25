class OrdersSweeper < ActionController::Caching::Sweeper
  observe Order # must declare the model you wish to observe, Rails unfriendly.

  include Rails.application.routes.url_helpers

  EXPIRABLE_FIELDS = ['agency_id', 'customer_id']
  ASSOCIATED_CLASSES = ['Customer', 'Unit', 'MasterFile', 'Agency', 'Bibl']

  # The after_update callback has a second expiry method for associated classes that is not required for
  # the destroy method since there should be no records associated with a destroyed record.
  def after_update(order)
    expire(order)
    expire_associated(order)
  end

  def after_create(order)
    expire(order)
    expire_associated(order)
  end

  def after_destroy(order)
    expire(order)
  end

  # Expire the index and show views for self
  def expire(order)
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_order_path(order.id)}")
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_orders_path}")
  end

  # Since subordinate classes often display Order information in their views, we need only to expire those cached views.
  # The classes which display Customer information on their show views are: Customers, Units, MasterFiles, Bibls, and Customers.
  #
  # Subordinate classes will only be expired if either :agency_id or :customer_id are changed.  Other values
  # should not change the show views of subordinate clases.
  def expire_associated(order)
    expirable = EXPIRABLE_FIELDS.any? do |key|
      order.changed_attributes.include?(key)
    end

    if expirable
      ASSOCIATED_CLASSES.each {|ac|
        PurgeCache.exec( {:subject_class => order.class.name, :subject_id => order.id, :associated_class => "#{ac}" })
      }
    end
  end
end
