class UnitsSweeper < ActionController::Caching::Sweeper
  observe Unit

  require 'activemessaging/processor'
  include ActiveMessaging::MessageSender
  include Rails.application.routes.url_helpers

  EXPIRABLE_FIELDS = ['order_id', 'bibl_id']
  ASSOCIATED_CLASSES = ['Customer', 'Order', 'MasterFile', 'Agency', 'Bibl']

  # The after_update callback has a second expiry method for associated classes that is not required for
  # the destroy method since there should be no records associated with a destroyed record.
  def after_update(unit)
    expire(unit)
    expire_associated(unit)
  end
  
  def after_create(unit)
    expire(unit)
    expire_associated(unit)
  end
  
  def after_destroy(unit)
    expire(unit)
  end
  
  # Expire the index and show views for self
  def expire(unit)
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_unit_path(unit.id)}")
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_units_path}")
  end

  # Since subordinate classes often display Order information in their views, we need only to expire those cached views.
  # The classes which display Customer information on their show views are: Customers, Orders, MasterFiles, Bibls, and Customers.
  #
  # Subordinate classes will only be expired if either :order_id or :bibl_id are changed.  Other values
  # should not change the show views of subordinate clases.
  def expire_associated(unit)
    expirable = EXPIRABLE_FIELDS.any? do |key|
      unit.changed_attributes.include?(key)
    end

    if expirable
      ASSOCIATED_CLASSES.each {|ac|
        publish :purge_cache, ActiveSupport::JSON.encode( {:subject_class => unit.class.name, :subject_id => unit.id, :associated_class => "#{ac}" }) 
      }
    end

  end
end
