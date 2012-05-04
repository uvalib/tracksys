module FixUpdateCounters

  def fix_updated_counters
    self.changes.each {|key, value|
      # key should match /master_files_id/ or /bibls_id/
      # value should be an array ['old value', 'new value']
      if key =~ /_id/
        changed_class = key.sub(/_id/, '')
        logger.info "#{self.class.name.downcase.pluralize}"
        changed_class.camelcase.constantize.decrement_counter(:"#{self.class.name.underscore.pluralize}_count", value[0]) unless value[0] == nil
        changed_class.camelcase.constantize.increment_counter(:"#{self.class.name.underscore.pluralize}_count", value[1]) unless value[1] == nil
      end
    }
  end 
end

ActiveRecord::Base.send(:include, FixUpdateCounters)
