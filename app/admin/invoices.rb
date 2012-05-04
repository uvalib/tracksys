ActiveAdmin.register Invoice do
  menu :parent => "Miscellaneous"

  scope :all, :default => true
end
