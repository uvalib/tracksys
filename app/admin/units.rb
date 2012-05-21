ActiveAdmin.register Unit do
  menu :priority => 4
  
  scope :all, :default => true
  scope :approved
  scope :unapproved
  scope :awaiting_copyright_approval
  scope :awaiting_condition_approval
  scope :canceled

  actions :all, :except => [:destroy]

  batch_action :print_routing_slips do |selection|

  end

  filter :id
  filter :date_archived
  filter :date_dl_deliverables_ready
  filter :date_queued_for_ingest
  filter :include_in_dl, :as => :select, :input_html => {:class => 'chzn-select'}
  filter :bibl_call_number, :as => :string, :label => "Call Number"
  filter :bibl_title, :as => :string, :label => "Bibl. Title"
  filter :order_id, :as => :numeric, :label => "Order ID"
  filter :customer_id, :as => :numeric, :label => "Customer ID"
  filter :agency, :as => :select, :input_html => {:class => 'chzn-select'}
  filter :indexing_scenario, :input_html => {:class => 'chzn-select'}
  filter :availability_policy, :input_html => {:class => 'chzn-select'}

  index do
    selectable_column
    column :id
    column ("Bibliographic Title") do |unit| 
      link_to "#{unit.bibl_title}", admin_bibl_path("#{unit.bibl_id}") 
    end
    column ("Call Number") {|unit| unit.bibl_call_number}
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
    column("Master Files") do |unit| 
      link_to unit.master_files_count, admin_master_files_path(:q => {:unit_id_eq => unit.id})
    end
    column("") do |unit|
      div do
        link_to "Details", resource_path(unit), :class => "member_link view_link"
      end
      div do
        link_to I18n.t('active_admin.edit'), edit_resource_path(unit), :class => "member_link edit_link"
      end
    end
  end

  show do
    div :class => 'two-column' do
      panel "General Information" do
        attributes_table_for unit do
          row :unit_status
          row :unit_extent_estimated
          row :unit_extent_actual
          row :heard_about_resource
          row :patron_source_url
          row :special_instructions
          row :staff_notes
        end
      end
    end

    div :class => 'two-column' do
      panel "Patron Request" do
        attributes_table_for unit do
          row :intended_use
          row :deliverable_format
          row :deliverable_resolution
          row :remove_watermark do |unit|
            format_boolean_as_yes_no(unit.remove_watermark)
          end
          row :date_materials_received do |unit|
            format_date(unit.date_materials_received)
          end
          row :date_materials_returned do |unit|
            format_date(unit.date_materials_returned)
          end
          row :date_archived do |unit|
            format_datetime(unit.date_archived)
          end
          row :date_patron_deliverables_ready do |unit|
            format_datetime(unit.date_patron_deliverables_ready)
          end
        end
      end
    end

    div :class => "columns-none" do
      panel "Digital Library Information", :toggle => 'hide' do
        attributes_table_for unit do 
          row :indexing_scenario
          row :availability_policy
          row :use_right
          row ("Digital Library Status") do |unit|
            case 
              when unit.include_in_dl?
                Unit.human_attribute_name(:include_in_dl)
              when unit.exclude_from_dl?
                Unit.human_attribute_name(:exclude_from_dl)
            end
          end
          row :master_file_discoverability do |unit|
            format_boolean_as_yes_no(unit.master_file_discoverability)
          end
          row :date_queued_for_ingest do |unit|
            format_datetime(unit.date_queued_for_ingest)
          end
          row :date_dl_deliverables_ready do |unit|
            format_datetime(unit.date_dl_deliverables_ready)
          end
        end
      end
    end
  end

  form do |f|
    f.inputs "General Information", :class => 'panel three-column ' do
      f.input :unit_status, :as => :select, :collection => Unit::UNIT_STATUSES
      f.input :unit_extent_estimated
      f.input :unit_extent_actual
      f.input :heard_about_resource, :as => :text, :input_html => { :disabled => true, :rows => 1 }
      f.input :patron_source_url,  :as => :text, :input_html => { :rows => 1 }
      f.input :special_instructions, :as => :text, :input_html => { :rows => 5 }
      f.input :staff_notes, :as => :text, :input_html => { :rows => 5 }
    end

    f.inputs "Patron Request", :class => 'panel three-column' do
      f.input :intended_use, :as => :select, :collection => IntendedUse.all, :input_html => {:class => 'chzn-select'}
      f.input :deliverable_format
      f.input :deliverable_resolution
      f.input :remove_watermark, :as => :radio
      f.input :date_materials_received, :as => :string, :input_html => {:class => :datepicker}
      f.input :date_materials_returned, :as => :string, :input_html => {:class => :datepicker}
      f.input :date_archived, :as => :string, :input_html => {:class => :datepicker}
      f.input :date_patron_deliverables_ready, :as => :string, :input_html => {:class => :datepicker}
    end

    f.inputs "Related Information", :class => 'panel three-column' do 
      f.input :order, :as => :select, :collection => Order.all, :input_html => {:class => 'chzn-select', :style => 'width: 200px'}
      f.input :bibl, :as => :select, :collection => Bibl.all, :input_html => { :class => 'chzn-select', :style => 'width: 250px'}
    end

    f.inputs "Digital Library Information", :class => 'columns-none panel', :toggle => 'hide' do
      f.input :indexing_scenario
      f.input :availability_policy
      f.input :use_right
      f.input :include_in_dl, :as => :radio
      f.input :exclude_from_dl, :as => :radio
      f.input :master_file_discoverability, :as => :radio
      f.input :date_queued_for_ingest, :as => :string, :input_html => {:class => :datepicker}
      f.input :date_dl_deliverables_ready, :as => :string, :input_html => {:class => :datepicker}
    end

    f.inputs :class => 'columns-none' do
      f.actions
    end

  end

  sidebar "Related Information", :only => [:show] do
    attributes_table_for unit do
      row :bibl
      row :order do |unit|
        link_to "##{unit.order.id}", admin_order_path(unit.order.id)
      end
      row :master_files do |unit|
        link_to "#{unit.master_files_count}", admin_master_files_path(:q => {:unit_id_eq => unit.id})
      end 
      row :customer
      row :automation_messages do |unit|
        link_to "#{unit.automation_messages_count}", admin_automation_messages_path(:q => {:messagable_id_eq => unit.id, :messagable_type_eq => "Unit" })
      end
      row :agency
    end
  end
end