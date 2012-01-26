ActiveAdmin.register AutomationMessage do
  menu :parent => "Miscellaneous"

  scope :all, :default => true
  scope :has_active_error
  scope :archive_workflow, :label => "Archive Workflow"
  scope :qa_workflow
  scope :patron_workflow
  scope :repository_workflow

  filter :active_error
  filter :message_type
  filter :processor

  index do
    column :id
    column :message_type
    column :active_error
    default_actions
  end

  # scope :all, :default => true
  # scope :has_active_error
  # # scope :archive_workflow, :label => "Archive Workflow"
  # # scope :qa_workflow
  # # scope :patron_workflow
  # # scope :repository_workflow
  # scope :errors
  # scope :failures
  # scope :success
  
  # form do |f|
  #   f.inputs "Details" do
  #   	f.input :message_type, :as => :select, :collection => AutomationMessage::MESSAGE_TYPES
  #     f.input :app, :as => :radio, :collection => AutomationMessage::APPS
  #     f.input :workflow_type, :as => :radio, :collection => AutomationMessage::WORKFLOW_TYPES
  #     f.input :message 
  #     f.input :active_error
  #   end
  #   f.buttons
  # end
end