ActiveAdmin.register Component do

  filter :component_type
  filter :title
  filter :content_desc
  filter :pid

  index do
    column :title
    column :date
    column("Description") {|component| component.content_desc }
    column :discoverability
    column :date_ingested_into_dl
    column :exemplar
    default_actions
  end
  
end
