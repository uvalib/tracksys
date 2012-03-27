require "#{Hydraulics.models_dir}/automation_message"

class AutomationMessage
  APPS.push('tracksys')

  default_scope order('id')

end
  