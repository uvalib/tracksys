
class AutomationMessageAssociationValidator < ActiveModel::EachValidator
   def validate_each(record)
      if not value =~ /^[a-z0-9_\.-]+@[a-z0-9_\.-]+\.[a-z0-9_-]+$/i
         record.errors.add(attribute, "should be of the format user@host.domain")
      end
   end
end
