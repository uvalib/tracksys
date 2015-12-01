ActiveAdmin.register Unit, :namespace => :patron do
  menu :priority => 4

  scope :all, :default => true
  scope :approved
  scope :unapproved
  scope :awaiting_copyright_approval
  scope :awaiting_condition_approval
  scope :canceled
  scope :overdue_materials
  scope :checkedout_materials
  
  actions :all, :except => [:destroy]

  batch_action :approve_units do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:unit_status, 'approved') }
    flash[:notice] = "Units #{selection.join(", ")} are now approved."
    redirect_to :back
  end

  batch_action :cancel_units do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:unit_status, 'canceled') }
    flash[:notice] = "Units #{selection.join(", ")} are now canceled."
    redirect_to :back
  end

  batch_action :check_condition_units do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:unit_status, 'condition') }
    flash[:notice] = "Units #{selection.join(", ")} need to be vetted for condition."
    redirect_to :back
  end

  batch_action :check_copyright_units do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:unit_status, 'copyright') }
    flash[:notice] = "Units #{selection.join(", ")} need to be vetted for copyright."
    redirect_to :back
  end

  batch_action :checkout_to_digiserv do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:date_materials_received, Time.now)}
    flash[:notice] = "Units #{select.join(", ")} are now checkedout to Digital Production Group."
    redirect_to :back
  end

  batch_action :checkin_from_digiserv do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:date_materials_returned, Time.now)}
    flash[:notice] = "Unit #{select.join(", ")} are now checked back in."
    redirect_to :back
  end

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
    column("Status") do |unit|
      status_tag(unit.unit_status)
    end
    column ("Bibliographic Record") do |unit|
      div do 
        link_to "#{unit.bibl_title}", patron_bibl_path("#{unit.bibl_id}") 
      end
      div do 
        unit.bibl_call_number
      end
    end
    column ("Date Checkedout") {|unit| format_date(unit.date_materials_received)}
    column ("Date Returned") {|unit| format_date(unit.date_materials_returned)}
    column :intended_use
    column("Master Files") do |unit| 
      link_to unit.master_files_count, patron_master_files_path(:q => {:unit_id_eq => unit.id})
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

  show :title => proc{|unit| "Unit ##{unit.id}"} do
    div :class => 'two-column' do
      panel "General Information" do
        attributes_table_for unit do
          row ("Status") do |unit|
            status_tag(unit.unit_status)
          end
          row :unit_extent_estimated
          row :unit_extent_actual
          row :heard_about_resource
          row :patron_source_url
          row :special_instructions do |unit|
            raw(unit.special_instructions.to_s.gsub(/\n/, '<br/>'))
          end
          row :staff_notes do |unit|
            raw(unit.staff_notes.to_s.gsub(/\n/, '<br/>'))
          end
        end
      end
    end

    div :class => 'two-column' do
      panel "Patron Request" do
        attributes_table_for unit do
          row :intended_use
          row :intended_use_deliverable_format
          row :intended_use_deliverable_resolution
          row :remove_watermark do |unit|
            format_boolean_as_yes_no(unit.remove_watermark)
          end
          row("Date Delivered to DigiServ") do |unit|
            format_date(unit.date_materials_received)
          end
          row("Date Returned from DigiServ") do |unit|
            format_date(unit.date_materials_returned)
          end
          row :date_archived do |unit|
            format_datetime(unit.date_archived)
          end
        end
      end
    end

    div :class => "columns-none" do
      if not unit.master_files.empty?
      then
        panel "Master Files", :toggle => 'show' do
          table_for unit.master_files do |mf|
            column :filename, :sortable => false
            column :title do |mf|
              truncate_words(mf.title)
            end
            column :description do |mf|
              truncate_words(mf.description)
            end
            column :date_archived do |mf|
              format_date(mf.date_archived)
            end
            column :date_dl_ingest do |mf|
              format_date(mf.date_dl_ingest)
            end
            column :pid, :sortable => false
            column("Thumbnail") do |mf|
              link_to image_tag(mf.link_to_static_thumbnail, :height => 125), "#{mf.link_to_static_thumbnail}", :rel => 'colorbox', :title => "#{mf.filename} (#{mf.title} #{mf.description})"
            end
            column("") do |mf|
              div do
                link_to "Details", patron_master_file_path(mf), :class => "member_link view_link"
              end
              div do
                link_to I18n.t('active_admin.edit'), edit_patron_master_file_path(mf), :class => "member_link edit_link"
              end
              if mf.in_dl?
                div do
                  link_to "Fedora", "#{FEDORA_REST_URL}/objects/#{mf.pid}", :class => 'member_link', :target => "_blank"
                end
              end
              if mf.date_archived
                div do
                  link_to "Download", copy_from_archive_patron_master_file_path(mf.id), :method => :put
                end
              end
            end          
          end
        end
      else
        panel "No Master Files Directly Associated with this Component"
      end
    end
  end

  form do |f|
    f.inputs "General Information", :class => 'panel three-column ' do
      f.input :unit_status, :as => :select, :collection => Unit::UNIT_STATUSES, :input_html => {:class => 'chzn-select', :style => 'width: 150px'}
      f.input :unit_extent_estimated
      f.input :special_instructions, :as => :text, :input_html => { :rows => 10 }
      f.input :staff_notes, :as => :text, :input_html => { :rows => 10 }
    end

    f.inputs "Patron Request", :class => 'panel three-column' do
      f.input :intended_use, :as => :select, :collection => IntendedUse.all, :input_html => {:class => 'chzn-select'}
      f.input :date_materials_received, :as => :string, :input_html => {:class => :datepicker}, :label => "Date Delivered to DigiServ"
      f.input :date_materials_returned, :as => :string, :input_html => {:class => :datepicker}, :label => "Date Returned from DigiServ"
    end

    f.inputs "Related Information", :class => 'panel three-column' do 
      f.input :order, :as => :select, :collection => Order.all, :input_html => {:class => 'chzn-select', :style => 'width: 200px'}
      f.input :bibl, :as => :select, :collection => Hash[Bibl.all.map{|b| [b.barcode,b.id]}], :label => "Bibliograhic Record Barcode", :input_html => { :class => 'chzn-select', :style => 'width: 250px'}
    end

    f.inputs :class => 'columns-none' do
      f.actions
    end
  end

  sidebar :approval_workflow, :only => :show do
    div :class => 'workflow_button' do button_to "Print Routing Slip", print_routing_slip_patron_unit_path, :method => :put end
    if unit.date_materials_received.nil? # i.e. Material has yet to be checked out to Digital Production Group
      div :class => 'workflow_button' do button_to "Check out to DigiServ", checkout_to_digiserv_patron_unit_path, :method => :put end
      div :class => 'workflow_button' do button_to "Check in from DigiServ", checkin_from_digiserv_patron_unit_path, :method => :put, :disabled => true end
    elsif unit.date_materials_received # i.e. Material has been checked out to Digital Production Group
      if unit.date_materials_returned.nil? # i.e. Material has been checkedout to Digital Production Group but not yet returned
        div :class => 'workflow_button' do button_to "Check out to DigiServ", checkout_to_digiserv_patron_unit_path, :method => :put, :disabled => true end
        div :class => 'workflow_button' do button_to "Check in from DigiServ", checkin_from_digiserv_patron_unit_path, :method => :put end
      else 
        div :class => 'workflow_button' do button_to "Check out to DigiServ", checkout_to_digiserv_patron_unit_path, :method => :put, :disabled => true end
        div :class => 'workflow_button' do button_to "Check in from DigiServ", checkin_from_digiserv_patron_unit_path, :method => :put, :disabled => true end
      end
    end
    if unit.date_archived
      div :class => 'workflow_button' do button_to "Download Unit From Archive", copy_from_archive_admin_unit_path(unit.id), :method => :put end
    else
      div :class => 'workflow_button' do button_to "Download Unit From Archive", copy_from_archive_admin_unit_path(unit.id), :method => :put, :disabled => true end
      div do "This unit cannot be downloaded because it is not archived." end
    end
  end

  sidebar "Related Information", :only => [:show] do
    attributes_table_for unit do
      row :bibl
      row :order do |unit|
        link_to "##{unit.order.id}", patron_order_path(unit.order.id)
      end
      row :master_files do |unit|
        link_to "#{unit.master_files_count}", patron_master_files_path(:q => {:unit_id_eq => unit.id})
      end 
      row :customer
      row :automation_messages do |unit|
        link_to "#{unit.automation_messages_count}", patron_automation_messages_path(:q => {:messagable_id_eq => unit.id, :messagable_type_eq => "Unit" })
      end
      row :agency
      row :archive
    end
  end

  action_item :only => :show do
    link_to("Previous", patron_unit_path(unit.previous)) unless unit.previous.nil?
  end

  action_item :only => :show do
    link_to("Next", patron_unit_path(unit.next)) unless unit.next.nil?
  end

  member_action :copy_from_archive, :method => :put do 
    Unit.find(params[:id]).get_from_stornext(request.env['HTTP_REMOTE_USER'].to_s)
    redirect_to :back, :notice => "Unit #{params[:id]} is now being downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR}."
  end

  member_action :print_routing_slip, :method => :put, :expires_in => 1.seconds do
    @unit = Unit.find(params[:id])
    @bibl = @unit.bibl
    @order = @unit.order
    @customer = @order.customer
    render :layout => 'routing_slip'
  end

  member_action :change_status
  member_action :checkout_to_digiserv, :method => :put do 
    Unit.find(params[:id]).update_attribute(:date_materials_received, Time.now)
    redirect_to :back, :notice => "Unit #{params[:id]} is now checked out to Digital Production Group."
  end

  member_action :checkin_from_digiserv, :method => :put do 
    Unit.find(params[:id]).update_attribute(:date_materials_returned, Time.now)
    redirect_to :back, :notice => "Unit #{params[:id]} has been returned from Digital Production Group."  
  end

  controller do
    require 'activemessaging/processor'
    include ActiveMessaging::MessageSender

    def change_status
      message = ActiveSupport::JSON.encode( { :unit_id => params[:id], :unit_status => params[:unit_status] })
      publish :update_unit_status, message
      flash[:notice] = "Unit #{params[:id]} status has been changed to #{params[:unit_status]}"
      redirect_to :back      
    end
  end
end
