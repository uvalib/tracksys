ActiveAdmin.register AvailabilityPolicy do
  config.sort_order = 'name_asc'
  menu :parent => "Controlled Vocabulary", if: proc{ current_user.admin? || current_user.supervisor? }

  # strong paramters handling
  permit_params :name, :repository_url, :pid

  config.clear_action_items!
  action_item :new, :only => :index do
     raw("<a href='/admin/availability_policies/new'>New</a>") if current_user.admin?
  end

  config.batch_actions = false
  config.filters = false

  index do
    column :name
    column :pid
    column("Metadata Records") do |availability_policy|
      availability_policy.metadata.count
    end
    column("") do |availability_policy|
      if current_user.admin?
         div do
           link_to I18n.t('active_admin.edit'), edit_resource_path(availability_policy), :class => "member_link edit_link"
         end
      end
    end
  end
end
