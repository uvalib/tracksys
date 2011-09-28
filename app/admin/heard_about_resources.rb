ActiveAdmin.register HeardAboutResource do
  menu :parent => "Miscellaneous"

  scope :all, :default => true
  scope :approved
  scope :not_approved
  scope :internal_use_only
  scope :publicly_available

  form do |f|
    f.inputs :description
    f.inputs :is_approved
    f.inputs :is_internal_use_only
  end

  show :title => :description do
  	panel "Units" do
      table_for (heard_about_resource.units) do
        column("ID") {|unit| link_to "#{unit.id}", admin_unit_path(unit) }
        column("Status") {|unit| unit.unit_status}
        column("Title") {|unit| unit.bibl_title}
        column("Call Number") {|unit| unit.bibl_call_number}
        column :date_archived
        column :date_dl_deliverables_ready
        column("# of Master Files") {|unit| unit.master_files_count.to_s}
      end
  	end
  end

  sidebar "Heard About Resource Details", :only => :show do
  	attributes_table_for heard_about_resource, :description
  end
  
end