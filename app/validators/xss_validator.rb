
class XssValidator < ActiveModel::EachValidator
   def validate_each(record, attribute, value)
      if value =~ /<|>/
         record.errors.add(attribute, "cannot have greater or less than (< or >) characters")
      end
   end
end
