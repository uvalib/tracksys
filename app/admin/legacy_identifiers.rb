ActiveAdmin.register LegacyIdentifier do
  menu :parent => "Miscellaneous"

  actions :all, :except => [:new, :destroy]
  scope :all, :default => true
end
