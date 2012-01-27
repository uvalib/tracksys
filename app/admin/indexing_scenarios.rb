ActiveAdmin.register IndexingScenario do
  menu :parent => "Miscellaneous"

  index do
    column :name
    column :pid
    column :datastream_name
    column :repository_url
    default_actions
  end
  
end
