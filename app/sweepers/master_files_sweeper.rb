class MasterFilesSweeper < ActionController::Caching::Sweeper
  observe MasterFile

  require 'activemessaging/processor'
  include ActiveMessaging::MessageSender
  include Rails.application.routes.url_helpers 

  EXPIRABLE_FIELDS = ['unit_id', 'component_id', 'filename', 'title', 'description', 'pid', 'date_archived', 'date_dl_ingest']
  ASSOCIATED_CLASSES = ['Customer', 'Order', 'Unit', 'Agency', 'Bibl', 'Component']

  # The after_update callback has a second expiry method for associated classes that is not required for
  # the destroy method since there should be no records associated with a destroyed record.
  def after_update(master_file)
    expire(master_file)
    expire_associated(master_file)
  end
  
  def after_create(master_file)
    expire(master_file)
    expire_associated(master_file)
  end
  
  def after_destroy(master_file)
    expire(master_file)
  end
  
  # Expire the index and show views for self
  def expire(master_file)
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_master_file_path(master_file.id)}")
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + "#{admin_master_files_path}")
  end

  # Since subordinate classes often display MasterFile information in their views, we need only to expire those cached views.
  # The classes which display Customer information on their show views are: Customers, Units, Orders, Bibls, and Components.
  #
  # Subordinate classes will only be expired if either :unit_id, :component_id, :filename, :title, :description, :pid, :date_archived: 
  # or :date_dl_ingest are changed.  Other values should not change the show views of subordinate clases.
  def expire_associated(master_file)
    Rails.logger.debug "MasterFilesSweeper: expire_associated will update #{master_file.class} #{master_file.id}'s expireable fields #{EXPIRABLE_FIELDS}"
    Rails.logger.debug "MasterFilesSweeper: expire_associated will update #{master_file.class} #{master_file.id}'s associated classes #{ASSOCIATED_CLASSES}"
    Rails.logger.debug "MasterFilesSweeper: #{master_file.class} #{master_file.id}'s changed attributes #{master_file.changed_attributes}"
    expirable = EXPIRABLE_FIELDS.any? do |key|
      master_file.changed_attributes.include?(key)
    end

    if expirable
      ASSOCIATED_CLASSES.each {|ac|
        msg = ActiveSupport::JSON.encode( {:subject_class => master_file.class.name, :subject_id => master_file.id, :associated_class => "#{ac}" })
        Rails.logger.debug "publishing to :purge_cache #{msg}"
        publish :purge_cache, msg
      }
    end

  end
end
