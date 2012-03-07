ActiveAdmin.register UseRight do
  menu :parent => "Miscellaneous"  

  config.sort_order = 'name_asc'

  index do
    column :id
    column :name
    column :description
    column("Bibls") do |use_right|
      link_to use_right.bibls_count.to_s, "bibls?q%5Buse_right_id_eq%5D=#{use_right.id}&order=title_asc"
    end
    column("Components") do |use_right|
      link_to use_right.components_count.to_s, "components?q%5Buse_right_id_eq%5D=#{use_right.id}&order=name_asc"
    end
    column("Master Files") do |use_right|
      link_to use_right.master_files_count.to_s, "master_files?q%5Buse_right_id_eq%5D=#{use_right.id}&order=id_asc"
    end
    column("Units") do |use_right|
      link_to use_right.units_count.to_s, "units?q%5Buse_right_id_eq%5D=#{use_right.id}&order=id_asc"
    end
  end
end
