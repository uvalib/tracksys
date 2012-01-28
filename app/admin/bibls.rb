ActiveAdmin.register Bibl do
  menu :priority => 5

  scope :all, :default => true
  scope :approved
  scope :not_approved

  filter :title
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