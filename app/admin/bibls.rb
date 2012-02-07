ActiveAdmin.register Bibl do
  menu :priority => 5

  scope :all, :default => true
  scope :approved
  scope :not_approved

  filter :title
  filter :call_number
  filter :creator_name
  filter :catalog_id, :label => "Catalog Key"
  filter :barcode
  filter :pid

  index do
  	column :id
  	column :title
  	column :creator_name
  	column :call_number
  	column :catalog_id
  	column :barcode
  	column :pid
    column("Units") {|bibl| bibl.units.size.to_s }
    column("Master Files") {|bibl| bibl.master_files.size.to_s }
    default_actions
  end
  
  show do
    panel "Units" do
      table_for bibl.units do
        column("ID") {|u| link_to "#{u.id}", admin_unit_path(u)}
        column ("DL Status") {|unit|
          case 
            when unit.include_in_dl?
              Unit.human_attribute_name(:include_in_dl)
            when unit.exclude_from_dl?
              Unit.human_attribute_name(:exclude_from_dl)
          end
        }
        column :date_archived
        column :date_patron_deliverables_ready
        column :date_queued_for_ingest
        column :date_dl_deliverables_ready
        column :intended_use
        column :master_files_count
      end
    end

    panel "Automation Messages" do
      table_for bibl.automation_messages do
        column("ID") {|am| link_to "#{am.id}", admin_automation_message_path(am)}
        column :message_type
        column :active_error
        column :workflow_type
        column(:message) {|am| truncate_words(am.message)}
        column(:created_at) {|am| format_date(am.created_at)}
        column("Sent By") {|am| "#{am.app.capitalize}, #{am.processor}"}
      end
    end
  end

  sidebar "Bibliographic Information", :only => :show do
    attributes_table_for bibl, :title, :creator_name, :call_number, :catalog_id, :barcode, :pid
  end


end