ActiveAdmin.register MasterFile, :namespace => :patron do
  menu :priority => 6

  config.sort_order = 'filename_asc'

 scope :all, :show_count => false, :default => true
  scope :in_digital_library, :show_count => false
  scope :not_in_digital_library, :show_count => false

  actions :all, :except => [:new, :destroy]

  batch_action :download_from_archive do |selection|
    MasterFile.find(selection).each {|s| s.get_from_stornext(current_user.computing_id) }
    flash[:notice] = "Master Files #{selection.join(", ")} are now being downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR}."
    redirect_to :back
  end

  filter :id
  filter :bibl_barcode, :as => :string, :label => "Barcode"
  filter :bibl_call_number, :as => :string, :label => "Call Number"
  filter :filename
  filter :title
  filter :description
  filter :transcription_text
  filter :pid
  filter :unit_id, :as => :numeric, :label => "Unit ID"
  filter :order_id, :as => :numeric, :label => "Order ID"
  filter :customer_id, :as => :numeric, :label => "Customer ID"
  filter :bibl_id, :as => :numeric, :label => "Bibl ID"
  filter :customer_last_name, :as => :string, :label => "Customer Last Name"
  filter :bibl_title, :as => :string, :label => "Bibl Title"
  filter :bibl_creator_name, :as => :string, :label => "Author"
  filter :bibl_catalog_key, :as => :string, :label => "Catalog Key"
  filter :academic_status, :as => :select
  filter :availability_policy
  filter :indexing_scenario
  filter :date_archived
  filter :date_dl_ingest
  filter :date_dl_update
  filter :agency, :as => :select
  filter :archive, :as => :select
  filter :heard_about_service, :as => :select
  filter :heard_about_resource, :as => :select

  index :id => 'master_files' do
    selectable_column
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
    column ("Bibliographic Title") do |mf|
      link_to "#{mf.bibl_title}", patron_bibl_path(mf.bibl.id)
    end
    column("Thumbnail") do |mf|
      link_to image_tag(mf.link_to_static_thumbnail, :height => 125), "#{mf.link_to_static_thumbnail}", :rel => 'colorbox', :title => "#{mf.filename} (#{mf.title} #{mf.description})"
    end
    column("") do |mf|
      div do
        link_to "Details", resource_path(mf), :class => "member_link view_link"
      end
      div do
        link_to I18n.t('active_admin.edit'), edit_resource_path(mf), :class => "member_link edit_link"
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

  show :title => proc {|mf| mf.filename } do
    div :class => 'two-column' do
      panel "General Information" do
        attributes_table_for master_file do
          row :filename
          row :title
          row :description
          row :date_archived do |master_file|
            format_date(master_file.date_archived)
          end
          row :transcription_text
        end
      end
    end
  end

  form do |f|
    f.inputs "General Information", :class => 'panel three-column ' do
      f.input :filename
      f.input :title
      f.input :description
      f.input :date_archived, :as => :string, :input_html => {:class => :datepicker}
      f.input :transcription_text, :input_html => { :rows => 5 }
    end

    f.inputs :class => 'columns-none' do
      f.actions
    end
  end

  sidebar "Thumbnail", :only => [:show] do
    div do
      link_to image_tag(master_file.link_to_static_thumbnail, :height => 250), "#{master_file.link_to_static_thumbnail}", :rel => 'colorbox', :title => "#{master_file.filename} (#{master_file.title} #{master_file.description})"
    end
    div do
      button_to "Print Image", print_image_admin_master_file_path, :method => :put
    end
  end

  sidebar "Related Information", :only => [:show] do
    attributes_table_for master_file do
      row :unit do |master_file|
        link_to "##{master_file.unit.id}", patron_unit_path(master_file.unit.id)
      end
      row :bibl
      row :order do |master_file|
        link_to "##{master_file.order.id}", patron_order_path(master_file.order.id)
      end
      row :customer
      row :component do |master_file|
        if not master_file.component.nil?
          link_to "#{master_file.component.name}", patron_component_path(master_file.component.id)
        end
      end
      row :automation_messages do |master_file|
        link_to "#{master_file.automation_messages_count}", patron_automation_messages_path(:q => {:messagable_id_eq => master_file.id, :messagable_type_eq => "MasterFile" })
      end
      row :agency
    end
  end

  action_item :only => :show do
    link_to("Previous", patron_master_file_path(master_file.previous)) unless master_file.previous.nil?
  end

  action_item :only => :show do
    link_to("Next", patron_master_file_path(master_file.next)) unless master_file.next.nil?
  end

  action_item :only => :show do
    if master_file.date_archived
      link_to "Download", copy_from_archive_patron_master_file_path(master_file.id), :method => :put
    end
  end

  member_action :copy_from_archive, :method => :put do
    mf = MasterFile.find(params[:id])
    mf.get_from_stornext(current_user.computing_id)
    redirect_to :back, :notice => "Master File #{mf.filename} is now being downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR}."
  end
end
