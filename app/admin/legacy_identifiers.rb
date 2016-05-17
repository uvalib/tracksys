ActiveAdmin.register LegacyIdentifier do
  menu :parent => "Miscellaneous"

  # strong paramters handling
  permit_params :label, :description, :legacy_identifier

  actions :all, :except => [:new, :destroy]
  config.batch_actions = false

  filter :id
  filter :label
  filter :description
  filter :legacy_identifier
  filter :created_at
  filter :updated_at

  index do
     column :id
     column :label
     column :description
     column :legacy_identifier
     column :created_at
     column :updated_at
     column("Links") do |legacy_identifier|
       div do
         link_to "Details", resource_path(legacy_identifier), :class => "member_link view_link"
       end
       if !current_user.viewer?
          div do
            link_to I18n.t('active_admin.edit'), edit_resource_path(legacy_identifier), :class => "member_link edit_link"
          end
       end
     end
  end
end
