ActiveAdmin.register IndexDestination do
  config.sort_order = 'nickname_asc'
  actions :all, :except => [:destroy]
  
  menu :parent => "Miscellaneous"

  scope :all, :default => true

  index do
    div :class => 'admin-information' do 
      h2 "Note: Index Destinations only control a flag generated and inserted in Solr records"
      h3 "They will always get posted to #{SOLR_URL}, and then pulled by Bob H. on request." 
    end
    column :nickname
    column :hostname
		column :port
		column :context
		column :url do |i| link_to "#{i.url}", i.url, :target => "_blank"  end 
		column :created_at
		column :updated_at
    column("Bibls") do |index_destination|
      link_to index_destination.bibls.size, admin_bibls_path(:q => {:index_destination_id_eq => index_destination.id}) 
    end
    column("Components") do |index_destination|
      link_to index_destination.components.size, admin_components_path(:q => {:index_destination_id_eq => index_destination.id})
    end
    column("Master Files") do |index_destination|
      link_to index_destination.master_files.size, admin_master_files_path(:q => {:index_destination_id_eq => index_destination.id})
    end
    column("Units") do |index_destination|
      link_to index_destination.units.size, admin_units_path(:q => {:index_destination_id_eq => index_destination.id})
    end
    default_actions
  end

  show do 
    panel "General Information" do
      attributes_table_for index_destination do
        row :name
        row :hostname
        row :port
        row :context
        row :url do |i| link_to "#{i.url}", i.url, :target => "_blank" end
        row :created_at
        row :updated_at
      end
    end
  end

  sidebar "Related Information", :only => [:show] do
    attributes_table_for index_destination do
      row("Units") do |index_destination|
        link_to index_destination.units.size, admin_units_path(:q => {:index_destination_id_eq => index_destination.id})
      end
      row("Master Files") do |index_destination|
        link_to index_destination.master_files.size, admin_master_files_path(:q => {:index_destination_id_eq => index_destination.id})
      end
      row("Bibls") do |index_destination|
        link_to index_destination.bibls.size, admin_bibls_path(:q => {:index_destination_id_eq => index_destination.id})
      end
      row("Components") do |index_destination|
        link_to index_destination.components.size, admin_components_path(:q => {:index_destination_id_eq => index_destination.id})
      end      
    end
  end
  
end
