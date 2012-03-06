ActiveAdmin.register AutomationMessage, :namespace => :patron do
  menu :parent => "Miscellaneous"

  scope :all, :default => true
  scope :has_active_error, :label => "Active Error"
  scope :has_inactive_error, :label => "Inactive Error"
  scope :archive_workflow
  scope :qa_workflow
  scope :patron_workflow
  scope :repository_workflow

  filter :active_error, :as => :select
  filter :message_type, :as => :select, :collection => AutomationMessage::MESSAGE_TYPES
  filter :processor, :as => :select, :collection => proc {AutomationMessage.select(:processor).order(:processor).uniq.map(&:processor)}
  filter :workflow_type, :as => :select, :collection => AutomationMessage::WORKFLOW_TYPES
  filter :bibl_id, :as => :numeric
  filter :component_id, :as => :numeric
  filter :master_file_id, :as => :numeric
  filter :order_id, :as => :numeric
  filter :unit_id, :as => :numeric

  index do
    column :id
    column :bibl
    column :component
    column :master_file
    column :order
    column :unit
    column :pid
    column :message_type
    column :workflow_type
    column :active_error
    column :message
    default_actions
  end

  show do 
    div :class => 'two-column' do
      panel "Details" do
        attributes_table_for automation_message do
          row :active_error
          row :workflow_type
          row :processor
          row :message_type
          row :app
          row :message
        end
      end
    end

    div :class => 'two-column' do
      panel "Relationships" do
        attributes_table_for automation_message do
          row :pid
          row :bibl
          row :component
          row :master_file
          row :order
          row :unit
        end
      end
    end
  end
  
  form do |f|
    f.inputs "Details", :class => 'two-column panel' do
      f.input :active_error, :as => :radio
      f.input :workflow_type, :as => :select, :collection => AutomationMessage::WORKFLOW_TYPES
      f.input :processor, :input_html => { :disabled => true }
      f.input :message_type, :input_html => { :disabled => true }
      f.input :app, :input_html => { :disabled => true}
      f.input :message, :as => :text, :input_html => { :rows => 10, :disabled => true }
    end
    f.inputs "Relationships", :class => 'two-column panel' do
      f.input :pid, :as => :string, :input_html => { :disabled => true }
      f.input :bibl_id, :as => :string, :input_html => { :disabled => true }
      f.input :component_id, :as => :string, :input_html => { :disabled => true }
      f.input :master_file_id, :as => :string, :input_html => { :disabled => true }
      f.input :order_id, :as => :string, :input_html => { :disabled => true }
      f.input :unit_id, :as => :string, :input_html => { :disabled => true }
    end
    f.inputs :class => 'columns-none' do
      f.buttons
    end
  end
end