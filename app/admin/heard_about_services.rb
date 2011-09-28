ActiveAdmin.register HeardAboutService do
  menu :parent => "Miscellaneous"

  scope :all, :default => true
  scope :approved
  scope :not_approved
  scope :internal_use_only
  scope :publicly_available

  form do |f|
    f.inputs :description
    f.inputs :is_approved
    f.inputs :is_internal_use_only
    f.buttons
  end
  
end