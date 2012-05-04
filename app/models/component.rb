require "#{Hydraulics.models_dir}/component"

class Component

  after_update :fix_updated_counters
end
