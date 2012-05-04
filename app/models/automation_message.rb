require "#{Hydraulics.models_dir}/automation_message"

class AutomationMessage
  APPS.push('tracksys')

  after_update :fix_updated_counters

end
  