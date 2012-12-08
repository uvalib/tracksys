ActiveAdmin.register Archive do
  menu :parent => "Miscellaneous"

  scope :all, :default => true
  actions :all, :except => [:destroy]

  filter :id
  filter :name

  index do
    column :name
    column :description
    column :directory
    column :units do |archive|
      link_to "#{archive.units.size}", admin_units_path(:q => {:archive_id_eq => archive.id})
    end
    column :master_files do |archive|
      link_to "#{archive.master_files.size}", admin_master_files_path(:q => {:archive_id_eq => archive.id})
    end
    column("") do |archive|
      div do
        link_to "Details", resource_path(archive), :class => "member_link view_link"
      end
      div do
        link_to I18n.t('active_admin.edit'), edit_resource_path(archive), :class => "member_link edit_link"
      end
    end
  end

  show do
    panel "Detailed Information" do
      attributes_table_for archive do
        row :name
        row :description
        row :directory
        row :created_at do |archive|
          format_date(archive.created_at)
        end
        row :updated_at do |archive|
          format_date(archive.updated_at)
        end
      end
    end
  end

  sidebar "Related Information", :only => :show do
    attributes_table_for archive do
      row :units do |archive|
        link_to "#{archive.units.size}", admin_units_path(:q => {:archive_id_eq => archive.id})
      end
      row :master_files do |academic_status|
        link_to "#{archive.master_files.size}", admin_master_files_path(:q => {:archive_id_eq => archive.id})
      end
    end
  end
end