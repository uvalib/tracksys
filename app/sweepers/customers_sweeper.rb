class CustomersSweeper < ActionController::Caching::Sweeper
  observe Customer
  include Rails.application.routes.url_helpers

  EXPIRABLE_FIELDS = ['first_name', 'last_name']
  ASSOCIATED_CLASSES = ['Order', 'Unit', 'MasterFile', 'Agency', 'Bibl']

  # The after_update callback has a second expiry method for associated classes that is not required for
  # the destroy method since there should be no records associated with a destroyed record.
  def after_update(customer)
    expire(customer)
    expire_associated(customer)
  end

  def after_create(customer)
    expire(customer)
    expire_associated(customer)
  end

  def after_destroy(customer)
    expire(customer)
  end

  # Expire the index and show views for self
  def expire(customer)
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_customer_path(customer.id)}")
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_customers_path}")
  end

  # Since subordinate classes often display Customer information in their views, we need only to expire those cached views.
  # The classes which display Customer information on their show views are: Orders, Units, MasterFiles, Bibls, and Agencies.
  #
  # Subordinate classes will only be expired if either :first_name or :last_name are changed.  Other values
  # should not change the show views of subordinate clases.
  def expire_associated(customer)
    expirable = EXPIRABLE_FIELDS.any? do |key|
      customer.changed_attributes.include?(key)
    end

    if expirable
      ASSOCIATED_CLASSES.each {|ac|
        PurgeCache.exec( {:subject_class => customer.class.name, :subject_id => customer.id, :associated_class => "#{ac}" })
      }
    end
  end
end
