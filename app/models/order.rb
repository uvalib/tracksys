require "#{Hydraulics.models_dir}/order"

class Order
  after_update :fix_updated_counters
end
