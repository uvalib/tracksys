ActiveAdmin.register IndexingScenario do
  config.sort_order = 'name_asc'
  actions :all, :except => [:destroy]
  
  menu :parent => "Miscellaneous"

  scope :all, :default => true

  index do
    column :name
    column :pid
    column :datastream_name
    column :repository_url
    column("Bibls") do |indexing_scenario|
      link_to indexing_scenario.bibls.size, admin_bibls_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id}) 
    end
    column("Components") do |indexing_scenario|
      link_to indexing_scenario.components.size, admin_components_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
    end
    column("Master Files") do |indexing_scenario|
      link_to indexing_scenario.master_files.size, admin_master_files_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
    end
    column("Units") do |indexing_scenario|
      link_to indexing_scenario.units.size, admin_units_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
    end
    default_actions
  end

  show do 
    panel "General Information" do
      attributes_table_for indexing_scenario do
        row :name
        row :pid
        row :datastream_name
        row :repository_url
        row :created_at
        row :updated_at
      end
    end
  end

  sidebar "Related Information", :only => [:show] do
    attributes_table_for indexing_scenario do
      row("Units") do |indexing_scenario|
        link_to indexing_scenario.units.size, admin_units_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
      end
      row("Master Files") do |indexing_scenario|
        link_to indexing_scenario.master_files.size, admin_master_files_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
      end
      row("Bibls") do |indexing_scenario|
        link_to indexing_scenario.bibls.size, admin_bibls_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
      end
      row("Components") do |indexing_scenario|
        link_to indexing_scenario.components.size, admin_components_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
      end      
    end
  end
  
end
