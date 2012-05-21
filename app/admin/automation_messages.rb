ActiveAdmin.register AutomationMessage do
  menu :priority => 8
  
  actions :all, :except => [:new]

  batch_action :remove_active_error do |selection|
    AutomationMessage.find(selection).each {|s| s.update_attribute(:active_error, false)}
    redirect_to :back, :alert => "Removed active error flag on #{successful_changes.length} Automation Messages."
  end

  scope :all, :default => true, :show_count => false
  scope "Active Error", :has_active_error
  scope "Inactive Error", :has_inactive_error, :show_count => false
  scope "Archive", :archive_workflow, :show_count => false
  scope "QA", :qa_workflow, :show_count => false
  scope "Delivery", :delivery_workflow, :show_count => false
  scope "Patron", :patron_workflow, :show_count => false
  scope "Production", :production_worklow, :show_count => false
  scope "Repository", :repository_workflow, :show_count => false

  filter :id
  filter :active_error, :as => :select, :input_html => {:class => 'chzn-select'}
  filter :message_type, :as => :select, :collection => AutomationMessage::MESSAGE_TYPES.sort.map(&:titleize), :input_html => {:class => 'chzn-select'}
  filter :processor, :as => :select, :collection => proc { AutomationMessage.select(:processor).order(:processor).uniq.map(&:processor).map(&:titleize) }, :input_html => {:class => 'chzn-select'}
  filter :workflow_type, :as => :select, :collection => AutomationMessage::WORKFLOW_TYPES.sort.map(&:titleize), :input_html => {:class => 'chzn-select'}
  filter :messagable_type, :as => :select, :collection => ['Bibl', 'MasterFile', 'Order', 'Unit'], :label => "Object", :input_html => {:class => 'chzn-select'}
  filter :messagable_id, :as => :numeric, :label => "Object ID"

  index do
    selectable_column
    column ("Attached to Object") do |automation_message|
      if automation_message.messagable
        link_to "#{automation_message.messagable_type} #{automation_message.messagable_id}", polymorphic_path([:admin, automation_message.messagable])
      else
        "None"
      end
    end
    column :processor do |automation_message|
      automation_message.processor.titleize
    end
    column :message_type do |automation_message|
      automation_message.message_type.to_s.capitalize
    end
    column :workflow_type do |automation_message|
      automation_message.workflow_type.to_s.capitalize
    end
    column :active_error do |automation_message|
      format_boolean_as_yes_no(automation_message.active_error)
    end
    column :message do |automation_message|
      truncate(automation_message.message, :length => 200)
    end
    column("") do |automation_message|
      div do
        link_to "Details", resource_path(automation_message), :class => "member_link view_link"
      end
      div do
        link_to I18n.t('active_admin.edit'), edit_resource_path(automation_message), :class => "member_link edit_link"
      end
    end
  end

  show :title => proc { automation_message.id } do 
    div :class => 'three-column' do
      panel "Details" do
        attributes_table_for automation_message do
          row :active_error do |automation_message|
            format_boolean_as_yes_no(automation_message.active_error)
          end
          row :workflow_type do |automation_message|
            automation_message.workflow_type.to_s.capitalize
          end
          row :processor do |automation_message|
            automation_message.processor.titleize
          end
          row :message_type do |automation_message|
            automation_message.message_type.to_s.capitalize
          end
          row :app do |automation_message|
            automation_message.app.titleize
          end
          row :message
        end
      end
    end

    div :class => 'three-column' do
      panel "Relationships" do
        attributes_table_for automation_message do
          row ("Attached to Object") do |automation_message|
            if automation_message.messagable
              link_to "#{automation_message.messagable_type} #{automation_message.messagable_id}", polymorphic_path([:admin, automation_message.messagable])
            else
              "None Available"
            end
          end
        end
      end
    end

    div :class => 'three-column' do
      panel "Technical Information" do
        attributes_table_for automation_message do
          row :created_at
          row :updated_at
          row :backtrace
        end
      end
    end
  end
  
  form do |f|
      if f.object.new_record? # New Record Logic
       f.inputs "Details", :class => 'two-column panel' do
        f.input :active_error, :as => :radio
        f.input :workflow_type, :as => :select, :collection => AutomationMessage::WORKFLOW_TYPES, :input_html => {:class => 'chzn-select'}
        f.input :processor, :collection => AutomationMessage.select(:processor).order(:processor).uniq.map(&:processor), :input_html => {:class => 'chzn-select'}
        f.input :message_type, :collection => AutomationMessage::MESSAGE_TYPES, :input_html => {:class => 'chzn-select'}
        f.input :app, :collection => AutomationMessage::APPS, :input_html => {:class => 'chzn-select'}
        f.input :message, :as => :text, :input_html => { :rows => 10}
      end
      f.inputs "Relationships", :class => 'two-column panel' do
        f.input :messagable_type, :as => :select 
        f.input :messagable_id, :as => :string
      end
    else  # Edit existing Record     
      f.inputs "Details", :class => 'three-column panel' do
        f.input :active_error, :as => :radio
        f.input :workflow_type, :as => :select, :collection => AutomationMessage::WORKFLOW_TYPES, :input_html => {:class => 'chzn-select'}
        f.input :processor, :input_html => { :disabled => true }
        f.input :message_type, :input_html => { :disabled => true }
        f.input :app, :input_html => { :disabled => true}
        f.input :message, :as => :text, :input_html => { :rows => 10, :disabled => true }
      end
      f.inputs "Relationships", :class => 'three-column panel' do
        f.input :pid, :as => :string, :input_html => { :disabled => true }
        f.input :messagable_type, :as => :string, :input_html => { :disabled => true }
        f.input :messagable_id, :as => :string, :input_html => { :disabled => true }
      end
      f.inputs "Technical Information", :class => 'three-column panel' do
        f.input :created_at, :as => :string, :input_html => { :disabled => true }
        f.input :updated_at, :as => :string, :input_html => { :disabled => true }
        f.input :backtrace, :input_html => { :disabled => true }
      end
    end
    f.inputs :class => 'columns-none' do
      f.actions
    end
  end
end
