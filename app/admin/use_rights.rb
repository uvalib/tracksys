ActiveAdmin.register UseRight do
  config.sort_order = 'name_asc'
  actions :all, :except => [:destroy]
  
  menu :parent => "Miscellaneous"  

  scope :all, :default => true

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

  show do
    panel "Basic Information" do
      attributes_table_for use_right do
        row :name
        row :description
        row :created_at
        row :updated_at
      end
    end
  end

  sidebar "Related Information", :only => [:show] do
    attributes_table_for use_right do
      row("Units") do |use_right|
        link_to use_right.units.size, admin_units_path(:q => {:use_right_id_eq => use_right.id})
      end
      row("Master Files") do |use_right|
        link_to use_right.master_files.size, admin_master_files_path(:q => {:use_right_id_eq => use_right.id})
      end
      row("Bibls") do |use_right|
        link_to use_right.bibls.size, admin_bibls_path(:q => {:use_right_id_eq => use_right.id})
      end
      row("Components") do |use_right|
        link_to use_right.components.size, admin_components_path(:q => {:use_right_id_eq => use_right.id})
      end      
    end
  end
end
