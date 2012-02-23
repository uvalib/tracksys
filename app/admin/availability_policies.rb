ActiveAdmin.register AvailabilityPolicy do
  menu :parent => "Miscellaneous"

  config.sort_order = 'name_asc'
  
  index do
    column :name
    column :xacml_policy_url
    column("Bibls") do |availability_policy|
      link_to availability_policy.bibls_count.to_s, "bibls?q%5Bavailability_policy_id_eq%5D=#{availability_policy.id}&order=title_asc"
    end
    column("Components") do |availability_policy|
      link_to availability_policy.components_count.to_s, "components?q%5Bavailability_policy_id_eq%5D=#{availability_policy.id}&order=name_asc"
    end
    column("Master Files") do |availability_policy|
      link_to availability_policy.master_files_count.to_s, "master_files?q%5Bavailability_policy_id_eq%5D=#{availability_policy.id}&order=id_asc"
    end
    column("Units") do |availability_policy|
      link_to availability_policy.units_count.to_s, "units?q%5Bavailability_policy_id_eq%5D=#{availability_policy.id}&order=id_asc"
    end
    default_actions
  end
end
