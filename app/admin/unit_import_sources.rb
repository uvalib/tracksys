ActiveAdmin.register UnitImportSource do
  menu :parent => "Miscellaneous"

  scope :all, :default => true

  filter :unit_id, :as => :numeric, :label => "Unit ID"
end
