
class PersonNameFormatValidator < ActiveModel::EachValidator
   def validate_each(record, attribute, value)
      if not value =~ /^([a-z\.\, \-']+)$/i
         record.errors.add(attribute, "should only contain alphabetic characters, period, comma, hyphen, and spaces")
      end
   end
end
