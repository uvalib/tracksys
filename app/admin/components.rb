ActiveAdmin.register Component do

  scope :all, :default => true

  filter :id
  filter :component_type
  filter :title
  filter :content_desc
  filter :pid
  filter :availability_policy
  filter :indexing_scenario

  index do
    selectable_column
    column :title
    column :date
    column("Description") {|component| component.content_desc }
    column :discoverability
    column :date_ingested_into_dl
    column :exemplar
    column("Links") do |customer|
      div do
        link_to "Details", resource_path(customer), :class => "member_link view_link"
      end
      div do
        link_to I18n.t('active_admin.edit'), edit_resource_path(customer), :class => "member_link edit_link"
      end
    end
  end
  
end
