class PurgeCacheProcessor < ApplicationProcessor
  
  subscribes_to :purge_cache, {:ack=>'client', 'activemq.prefetchSize' => 1}
  include Rails.application.routes.url_helpers # to support the route url's

  def on_message(message)
    hash = ActiveSupport::JSON.decode(message).symbolize_keys 
    raise "Parameter 'subject_class' is required" if hash[:subject_class].blank?
    raise "Parameter 'subject_id' is required" if hash[:subject_id].blank?
    raise "Parameter 'associated_class' is required" if hash[:associated_class].blank?

    subject_class = hash[:subject_class]
    subject_id = hash[:subject_id]
    associated_class = hash[:associated_class]
    
    purge_cache(subject_class.classify.constantize.find(subject_id), associated_class)
  end

  # Given a subject (i.e. an object whose record has just expired), all records associated 
  # with it from the associated class must also be purged as well.
  # 
  # The primary goal is to determine the relationship between two classes and delete the
  # associated cache accordingly, either iterating over an arary (in the case of a has_many or
  # has_and_belongs_to_many) or directly addressing the only associated object (in the case of 
  # a belongs_to or has_one).
  def purge_cache(subject, associated_class)
    @subject = subject
    @associated_class = associated_class

    # Get the appropriate relation.  Should return values like 'has_many' or 'belongs_to'
    @subject.class.reflect_on_all_associations.select{|a| a.class_name == "#{@associated_class.classify}"}.each do |association|
      @relationship = association.macro
    end

    case 
    when @relationship == :has_many || @relationship == :has_and_belongs_to_many
      # @associated_class must be pluralized because of the nature of the relationship
      @subject.send(@associated_class.classify.underscore.pluralize).each {|associated_object|
        expire_cache(associated_object)
      }
    when @relationship == :belongs_to || @relationship == :has_one
      # Note that @associated_class lacks a pluralize method
      associated_object = @subject.send(@associated_class.classify.underscore)
      expire_cache(associated_object)
    else
      logger.debug "Unknown"
    end
  end

  # Manually delete the show view of the associated object
  def expire_cache(associated_object)
    Rails.cache.delete("views/tracksys.lib.virginia.edu" + eval("admin_#{associated_object.class.name.underscore}_path(#{associated_object.id})"))
  end
end
