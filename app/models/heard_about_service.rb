require "#{Hydraulics.models_dir}/heard_about_service"

class HeardAboutService
  default_scope :order => :description
  scope :for_request_form, where(:is_approved => true).where(:is_internal_use_only => false)
end
# == Schema Information
#
# Table name: heard_about_services
#
#  id                   :integer(4)      not null, primary key
#  description          :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  is_approved          :boolean(1)      default(FALSE), not null
#  is_internal_use_only :boolean(1)      default(FALSE), not null
#  customers_count      :integer(4)      default(0)
#

