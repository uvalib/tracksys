
class PhoneFormatValidator < ActiveModel::EachValidator
   def validate_each(record, attribute, value)
      if not value =~ /^([0-9\.+ -]+)$/i
         record.errors.add(attribute, "should only contain digits, period, plus sign, hyphen, and spaces")
      end
   end
end
