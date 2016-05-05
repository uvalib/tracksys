ActiveAdmin.register Unit do
  menu :priority => 4

  # strong paramters handling
  permit_params :unit_status, :unit_extent_estimated, :unit_extent_actual, :special_instructions, :staff_notes,
     :intended_use_id, :remove_watermark, :date_materials_received, :date_materials_returned, :date_archived,
     :date_patron_deliverables_ready, :patron_source_url, :order_id, :bibl_id, :index_scenario_id, :availability_policy_id,
     :include_in_dl,  :exclude_from_dl, :master_file_discoverability, :date_queued_for_ingest, :date_dl_deliverables_ready

  scope :all, :default => true
  scope :approved
  scope :unapproved
  scope :awaiting_copyright_approval
  scope :awaiting_condition_approval
  scope :canceled
  scope :uncompleted_units_of_partially_completed_orders
  scope :ready_for_repo

  csv do
    column :id
    column :bibl_title
    column :bibl_call_number
    column("Date Archived") {|unit| format_date(unit.date_archived)}
    column :master_files_count
  end

  config.clear_action_items!
  action_item :new, :only => :index do
     raw("<a href='/admin/units/new'>New</a>") if !current_user.viewer?
  end
  action_item :ocr, only: :show do
     link_to "OCR", "/admin/ocr?u=#{unit.id}"  if !current_user.viewer? && ocr_enabled?
  end
  action_item :edit, only: :show do
     link_to "Edit", edit_resource_path  if !current_user.viewer?
  end

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

  batch_action :include_in_dl_units do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:include_in_dl, true) }
    Unit.find(selection).each {|s| s.update_attribute(:exclude_from_dl, false) }
    flash[:notice] = "Units #{selection.join(", ")} have been marked for inclusion in the Digital Library."
    redirect_to :back
  end

  batch_action :exclude_from_dl_units do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:exclude_from_dl, true) }
    Unit.find(selection).each {|s| s.update_attribute(:include_in_dl, false) }
    flash[:notice] = "Units #{selection.join(", ")} have been marked for exclusion from the Digital Library."
    redirect_to :back
  end

  batch_action :print_routing_slips do |selection|

  end

  filter :id
  filter :date_archived
  filter :date_dl_deliverables_ready
  filter :date_queued_for_ingest
  filter :special_instructions
  filter :staff_notes
  filter :include_in_dl, :as => :select
  filter :intended_use, :as => :select
  filter :bibl_call_number, :as => :string, :label => "Call Number"
  filter :bibl_title, :as => :string, :label => "Bibl. Title"
  filter :order_id, :as => :numeric, :label => "Order ID"
  filter :customer_id, :as => :numeric, :label => "Customer ID"
  filter :agency, :as => :select
  filter :indexing_scenario
  filter :availability_policy
  filter :master_files_count, :as => :numeric

  index do
    selectable_column
    column :id
    column("Status") do |unit|
      status_tag(unit.unit_status)
    end
    column ("Bibliographic Record") do |unit|
      div do
         if !unit.bibl_id.nil?
            link_to "#{unit.bibl_title}", admin_bibl_path("#{unit.bibl_id}")
         end
      end
      div do
        unit.bibl_call_number
      end
    end
    column ("DL Status") do |unit|
      case
        when unit.include_in_dl?
          Unit.human_attribute_name(:include_in_dl)
        when unit.exclude_from_dl?
          Unit.human_attribute_name(:exclude_from_dl)
      end
    end
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
      if !current_user.viewer?
         div do
           link_to I18n.t('active_admin.edit'), edit_resource_path(unit), :class => "member_link edit_link"
         end
         if ocr_enabled?
            div do
               link_to "OCR", "/admin/ocr?u=#{unit.id}"
            end
         end
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
            column :transcription_text do |mf|
              truncate_words(raw(mf.transcription_text))
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
                link_to "Details", admin_master_file_path(mf), :class => "member_link view_link"
              end
              if !current_user.viewer?
                 div do
                   link_to I18n.t('active_admin.edit'), edit_admin_master_file_path(mf), :class => "member_link edit_link"
                 end
                 if ocr_enabled?
                    div do
                       link_to "OCR", "/admin/ocr?mf=#{mf.id}"
                    end
                 end
              end
              if mf.in_dl?
                div do
                  link_to "Fedora", "#{FEDORA_REST_URL}/objects/#{mf.pid}", :class => 'member_link', :target => "_blank"
                end
                div do
                  link_to "Solr", "#{STAGING_SOLR_URL}/select?q=id:\"#{mf.pid}\"", :class => 'member_link', :target => "_blank"
                end
              end
              if mf.date_archived
                div do
                  link_to "Download", copy_from_archive_admin_master_file_path(mf.id), :method => :put
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
      f.input :unit_status, :as => :select, :collection => Unit::UNIT_STATUSES
      f.input :unit_extent_estimated
      f.input :unit_extent_actual
      f.input :special_instructions, :as => :text, :input_html => { :rows => 5 }
      f.input :staff_notes, :as => :text, :input_html => { :rows => 5 }
    end

    f.inputs "Patron Request", :class => 'panel three-column' do
      f.input :intended_use, :as => :select, :collection => IntendedUse.all
      f.input :remove_watermark, :as => :radio
      f.input :date_materials_received, :as => :string, :input_html => {:class => :datepicker}
      f.input :date_materials_returned, :as => :string, :input_html => {:class => :datepicker}
      f.input :date_archived, :as => :string, :input_html => {:class => :datepicker}
      f.input :date_patron_deliverables_ready, :as => :string, :input_html => {:class => :datepicker}
      f.input :patron_source_url,  :as => :text, :input_html => { :rows => 1 }
    end

    f.inputs "Related Information", :class => 'panel three-column' do
      f.input :order, :as => :select, :collection => Order.all, :input_html => {:class => 'chosen-select', :style => 'width: 200px'}
      f.input :bibl, :as => :select, :collection => Hash[Bibl.all.map{|b| [b.barcode,b.id]}], :input_html => { :class => 'chosen-select', :style => 'width: 200px'}
    end

    f.inputs "Digital Library Information", :class => 'columns-none panel', :toggle => 'hide' do
      f.input :indexing_scenario
      f.input :availability_policy
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

  # sidebar "Related Information", :only => [:show] do
  #   attributes_table_for unit do
  #     row :bibl
  #     row :order do |unit|
  #       link_to "##{unit.order.id}", admin_order_path(unit.order.id)
  #     end
  #     row :master_files do |unit|
  #       link_to "#{unit.master_files_count}", admin_master_files_path(:q => {:unit_id_eq => unit.id})
  #     end
  #     row :customer
  #     row :agency
  #     row "Legacy Identifiers" do |unit|
  #      	unit.legacy_identifiers.each {|li|
  #         div do
  #           link_to "#{li.description} (#{li.legacy_identifier})", admin_legacy_identifier_path(li)
  #         end
  #       } unless unit.legacy_identifiers.empty?
  #     end
  #   end
  # end

  sidebar :approval_workflow, :only => :show,  if: proc{ !current_user.viewer? } do
    div :class => 'workflow_button' do button_to "Print Routing Slip", print_routing_slip_admin_unit_path, :method => :put end

    if unit.date_materials_received.nil? # i.e. Material has yet to be checked out to Digital Production Group
      div :class => 'workflow_button' do button_to "Check out to DigiServ", checkout_to_digiserv_admin_unit_path, :method => :put end
      div :class => 'workflow_button' do button_to "Check in from DigiServ", checkin_from_digiserv_admin_unit_path, :method => :put, :disabled => true end
    elsif unit.date_materials_received # i.e. Material has been checked out to Digital Production Group
      if unit.date_materials_returned.nil? # i.e. Material has been checkedout to Digital Production Group but not yet returned
        div :class => 'workflow_button' do button_to "Check out to DigiServ", checkout_to_digiserv_admin_unit_path, :method => :put, :disabled => true end
        div :class => 'workflow_button' do button_to "Check in from DigiServ", checkin_from_digiserv_admin_unit_path, :method => :put end
      else
        div :class => 'workflow_button' do button_to "Check out to DigiServ", checkout_to_digiserv_admin_unit_path, :method => :put, :disabled => true end
        div :class => 'workflow_button' do button_to "Check in from DigiServ", checkin_from_digiserv_admin_unit_path, :method => :put, :disabled => true end
      end
    end
  end

  sidebar "Delivery Workflow", :only => [:show] do
    if !current_user.viewer?
       if File.exist?(File.join(IN_PROCESS_DIR, "%09d" % unit.id))
            if not unit.date_archived
              div :class => 'workflow_button' do button_to "QA Unit Data", qa_unit_data_admin_unit_path , :method => :put end
              div :class => 'workflow_button' do button_to "QA Filesystem and XML", qa_filesystem_and_iview_xml_admin_unit_path , :method => :put end
              div :class => 'workflow_button' do button_to "Create Master File Records", import_unit_iview_xml_admin_unit_path, :method => :put end
              div :class => 'workflow_button' do button_to "Send Unit to Archive", send_unit_to_archive_admin_unit_path, :method => :put end
            end
            if not unit.date_patron_deliverables_ready and not unit.intended_use == 'Digital Collection Buidling'
              div :class => 'workflow_button' do button_to "Begin Generate Deliverables", check_unit_delivery_mode_admin_unit_path, :method => :put end
              # <%=button_to "Begin Generate Deliverables", {:action=>"check_unit_delivery_mode", :unit_id => unit.id, :order_id => unit.order.id} %>
            end

            if unit.date_archived and unit.date_patron_deliverables_ready and not unit.intended_use == 'Digital Collection Building'
              div do "This unit has been archived and patron deliverables are generated.  There are no more finalization steps available." end
            end
       else
         div do "Files for this unit do not reside in the finalization directory. No work can be done on them." end
       end
    end

    if unit.date_archived
      div :class => 'workflow_button' do button_to "Download Unit From Archive", copy_from_archive_admin_unit_path(unit.id), :method => :put end
    else
      div :class => 'workflow_button' do button_to "Download Unit From Archive", copy_from_archive_admin_unit_path(unit.id), :method => :put, :disabled => true end
      div do "This unit cannot be downloaded because it is not archived." end
    end
  end

  sidebar "Digital Library Workflow", :only => [:show],  if: proc{ !current_user.viewer? } do
    if unit.ready_for_repo?
      div :class => 'workflow_button' do button_to "Put into Digital Library", start_ingest_from_archive_admin_unit_path(:datastream => 'all'), :method => :put end
    end
    if unit.in_dl?
      if ( unit.master_files.last.kind_of?(MasterFile) && ! unit.master_files.last.exists_in_repo? )
        div :class => 'workflow_note' do "Warning: last MasterFile in this unit not found in #{FEDORA_REST_URL}" end
      end
      div :class => 'workflow_button' do button_to "Update All Datastreams", update_metadata_admin_unit_path(:datastream => 'all'), :method => :put end
      div :class => 'workflow_button' do button_to "Update All XML Datastreams", update_metadata_admin_unit_path(:datastream => 'allxml'), :method => :put end
      div :class => 'workflow_button' do button_to "Update Dublin Core", update_metadata_admin_unit_path(:datastream => 'dc_metadata'), :method => :put end
      div :class => 'workflow_button' do button_to "Update Descriptive Metadata", update_metadata_admin_unit_path(:datastream => 'desc_metadata'), :method => :put end
      div :class => 'workflow_button' do button_to "Update Relationships", update_metadata_admin_unit_path(:datastream => 'rels_ext'), :method => :put end
      div :class => 'workflow_button' do button_to "Update Index Records", update_metadata_admin_unit_path(:datastream => 'solr_doc'), :method => :put end
    end
  end

  sidebar "Solr Index", :only => [:show],  if: proc{ !current_user.viewer? } do
    if unit.in_dl?
      div :class => 'workflow_button' do button_to "Commit Records to Solr", update_all_solr_docs_admin_unit_path, :user => current_user, :method => :get end
    end
  end

  action_item :previous, :only => :show do
    link_to("Previous", admin_unit_path(unit.previous)) unless unit.previous.nil?
  end

  action_item :next, :only => :show do
    link_to("Next", admin_unit_path(unit.next)) unless unit.next.nil?
  end

  member_action :print_routing_slip, :method => :put do
    @unit = Unit.find(params[:id])
    @bibl = @unit.bibl
    @order = @unit.order
    @customer = @order.customer
    render :layout => 'printable'
  end

  # Member actions for workflow
  member_action :check_unit_delivery_mode, :method => :put do
    Unit.find(params[:id]).check_unit_delivery_mode
    redirect_to :back, :notice => "Workflow started at the checking of the unit's delivery mode."
  end

  member_action :copy_from_archive, :method => :put do
    Unit.find(params[:id]).get_from_stornext( current_user.computing_id )
    redirect_to :back, :notice => "Unit #{params[:id]} is now being downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR} under your username."
  end

  member_action :import_unit_iview_xml, :method => :put do
    Unit.find(params[:id]).import_unit_iview_xml
    redirect_to :back, :notice => "Workflow started at the importation of the Iview XML and creation of master files."
  end

  member_action :qa_filesystem_and_iview_xml, :method => :put do
    Unit.find(params[:id]).qa_filesystem_and_iview_xml
    redirect_to :back, :notice => "Workflow started at QA of filesystem and Iview XML."
  end

  member_action :qa_unit_data, :method => :put do
    Unit.find(params[:id]).qa_unit_data
    redirect_to :back, :notice => "Workflow started at QA unit data."
  end

  member_action :send_unit_to_archive, :method => :put do
    Unit.find(params[:id]).send_unit_to_archive
    redirect_to :back, :notice => "Workflow started at the archiving of the unit."
  end

  member_action :start_ingest_from_archive, :method => :put do
    Unit.find(params[:id]).start_ingest_from_archive
    redirect_to :back, :notice => "Unit being put into digital library."
  end

  member_action :update_metadata, :method => :put do
    Unit.find(params[:id]).update_metadata(params[:datastream])
    redirect_to :back, :notice => "#{params[:datastream]} is being updated."
  end

  member_action :update_all_solr_docs do
    SendCommitToSolr.exec()
    flash[:notice] = "All Solr records have been committed to #{STAGING_SOLR_URL}."
    redirect_to :back
  end

  member_action :checkout_to_digiserv, :method => :put do
    Unit.find(params[:id]).update_attribute(:date_materials_received, Time.now)
    redirect_to :back, :notice => "Unit #{params[:id]} is now checked out to Digital Production Group."
  end

  member_action :checkin_from_digiserv, :method => :put do
    Unit.find(params[:id]).update_attribute(:date_materials_returned, Time.now)
    redirect_to :back, :notice => "Unit #{params[:id]} has been returned from Digital Production Group."
  end
end
