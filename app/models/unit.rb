require "#{Hydraulics.models_dir}/unit"

class Unit

  after_update :fix_updated_counters
end
