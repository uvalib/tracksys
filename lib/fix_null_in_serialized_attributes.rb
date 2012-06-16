module ActiveRecord
  module Coders
    class YAMLColumn
 
      def dump(obj)
        YAML.dump(obj) unless obj.nil?
      end
    end
  end
end