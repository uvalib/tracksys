ActiveAdmin.register Unit do
  menu :priority => 4
  
  scope :all, :default => true

  filter :date_archived
  filter :date_dl_deliverables_ready
  filter :date_queued_for_ingest
  filter :include_in_dl, :as => :select
  # filter :exclude_from_dl, :as => :radio
  filter :bibl_call_number, :as => :string, :label => "Call Number"
  filter :bibl_title, :as => :string, :label => "Bibl. Title"
  filter :indexing_scenario

  index do
    column :id
    column :bibl
    # column ("Bibl Title") {|unit| unit.bibl_title }
    # column ("Call Number") {|unit| unit.bibl_call_number}
    column ("DL Status") {|unit|
      case 
        when unit.include_in_dl?
          Unit.human_attribute_name(:include_in_dl)
        when unit.exclude_from_dl?
          Unit.human_attribute_name(:exclude_from_dl)
      end
    }
    column :date_archived do |unit|
      format_date(unit.date_archived)
    end
    column :date_queued_for_ingest do |unit|
      format_date(unit.date_queued_for_ingest)
    end
    column :date_dl_deliverables_ready do |unit|
      format_date(unit.date_dl_deliverables_ready)
    end
    column :intended_use
    default_actions
  end

  show do
  	panel "Master Files" do
  		table_for(unit.master_files) do
  			column ("ID") {|master_file| link_to "#{master_file.id}", admin_master_file_path(master_file) }
  			column :title
  			column :description
  			column :pid
  		end
  	end
  end

  sidebar "Patron Information", :only => [:show] do
    attributes_table_for unit, :intended_use_id
  end
  
end
