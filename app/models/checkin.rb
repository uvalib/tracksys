require "#{Hydraulics.models_dir}/checkin"

class Checkin

  after_update :fix_updated_counters
end
