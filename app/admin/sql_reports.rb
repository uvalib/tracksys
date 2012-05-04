ActiveAdmin.register SqlReport do
  menu :parent => "Miscellaneous"

  scope :all, :default => true

  filter :name
  filter :description
  filter :sql

  index do
    column :name
    column :description
    default_actions
  end
end
