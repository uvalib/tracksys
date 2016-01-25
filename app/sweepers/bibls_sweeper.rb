class BiblsSweeper < ActionController::Caching::Sweeper
  observe Bibl
  include Rails.application.routes.url_helpers

  EXPIRABLE_FIELDS = ['title', 'call_number']
  ASSOCIATED_CLASSES = ['Customer', 'Unit', 'MasterFile', 'Agency', 'Order']

  # The after_update callback has a second expiry method for associated classes that is not required for
  # the destroy method since there should be no records associated with a destroyed record.
  def after_update(bibl)
    expire(bibl)
    expire_associated(bibl)
  end

  def after_create(bibl)
    expire(bibl)
    expire_associated(bibl)
  end

  def after_destroy(bibl)
    expire(bibl)
  end

  # Expire the index and show views for self
  def expire(bibl)
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_bibl_path(bibl.id)}")
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_bibls_path}")
  end

  # Since subordinate classes often display Bibl information in their views, we need only to expire those cached views.
  # The classes which display Bibl information on their show views are: Customers, Units, MasterFiles, Agencies and Orders.
  #
  # TODO: Consider relationship between Components and Bibls for possible expiration.
  #
  # Subordinate classes will only be expired if either :call_number or :title are changed.  Other values
  # should not change the show views of subordinate clases.
  #
  # TODO: Might possible need to expire if :creator_name is changed.  Currently not displayed on show views.
  def expire_associated(bibl)
    expirable = EXPIRABLE_FIELDS.any? do |key|
      bibl.changed_attributes.include?(key)
    end

    if expirable
      ASSOCIATED_CLASSES.each {|ac|
        PurgeCache.exec( {:subject_class => bibl.class.name, :subject_id => bibl.id, :associated_class => "#{ac}" })
      }
    end

  end
end
