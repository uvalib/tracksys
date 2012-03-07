ActiveAdmin.register IndexingScenario do
  config.sort_order = 'name_asc'
  
  menu :parent => "Miscellaneous"

  index do
    column :name
    column :pid
    column :datastream_name
    column :repository_url
    column("Bibls") do |indexing_scenario|
      link_to indexing_scenario.bibls_count.to_s, "bibls?q%5Bindexing_scenario_id_eq%5D=#{indexing_scenario.id}&order=title_asc"
    end
    column("Components") do |indexing_scenario|
      link_to indexing_scenario.components_count.to_s, "components?q%5Bindexing_scenario_id_eq%5D=#{indexing_scenario.id}&order=name_asc"
    end
    column("Master Files") do |indexing_scenario|
      link_to indexing_scenario.master_files_count.to_s, "master_files?q%5Bindexing_scenario_id_eq%5D=#{indexing_scenario.id}&order=id_asc"
    end
    column("Units") do |indexing_scenario|
      link_to indexing_scenario.units_count.to_s, "units?q%5Bindexing_scenario_id_eq%5D=#{indexing_scenario.id}&order=id_asc"
    end
    default_actions
  end
  
end
