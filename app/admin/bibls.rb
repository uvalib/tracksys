ActiveAdmin.register Bibl do
  menu :priority => 5

  actions :all

  scope :all, :default => true
  scope :approved
  scope :not_approved
  scope :in_digital_library
  scope :not_in_digital_library

  filter :id
  filter :title
  filter :call_number
  filter :creator_name
  filter :catalog_key
  filter :barcode
  filter :pid
  filter :location
  filter :resource_type, :as => :select, :collection => Bibl.select(:resource_type).order(:resource_type).uniq.map(&:resource_type), :input_html => {:class => 'chzn-select'}
  filter :availability_policy, :input_html => {:class => 'chzn-select'}
  filter :customers_id, :as => :numeric
  filter :orders_id, :as => :numeric
  filter :agencies_id, :as => :numeric

  index :id => 'bibls' do
    selectable_column
    column :title
    column :creator_name
    column :call_number
    column :volume
    column :catalog_key do |bibl|
      div do
        bibl.catalog_key
      end
      if bibl.in_catalog?
        div do
          link_to "VIRGO", bibl.physical_virgo_url, :target => "_blank"
        end
      end
    end
    column :barcode
    column :location
    column ("Digital Library?") do |bibl|
      div do
        format_boolean_as_yes_no(bibl.in_dl?)
      end
      if bibl.in_dl?
        div do
          link_to "VIRGO", bibl.dl_virgo_url, :target => "_blank"
        end
        div do
          link_to "Fedora", bibl.fedora_url, :target => "_blank"
        end
      end
    end
    column :units do |bibl|
      link_to bibl.units.size, admin_units_path(:q => {:bibl_id_eq => bibl.id})
    end
    column("Master Files") do |bibl|
      link_to bibl.master_files.size, admin_master_files_path(:q => {:bibl_id_eq => bibl.id})
    end
    column("Links") do |bibl|
      div do
        link_to "Details", resource_path(bibl), :class => "member_link view_link"
      end
      div do
        link_to I18n.t('active_admin.edit'), edit_resource_path(bibl), :class => "member_link edit_link"
      end
    end
  end
  
  show :title => proc { truncate(bibl.title, :length => 75) } do
    div :class => 'three-column' do
      panel "Basic Information", :toggle => 'show' do
        attributes_table_for bibl do
          row :catalog_key
          row :barcode
          row :title
          row :creator_name
          row :creator_name_type
          row :call_number
          row :year
          row :year_type
          row :copy
          row :location
        end
      end
    end

    div :class => 'three-column' do
      panel "Detailed Bibliographic Information", :toggle => 'show' do
        attributes_table_for bibl do
          row :citation
          row :description
          row :title_control
          row :series_title
          row :volume
          row :issue
        end
      end
    end

    div :class => 'three-column' do
      panel "Administrative Information", :toggle => 'show' do
        attributes_table_for bibl do
          row :is_approved do |bibl|
            format_boolean_as_yes_no(bibl.is_approved)
          end
          row :is_personal_item do |bibl|
            format_boolean_as_yes_no(bibl.is_personal_item)
          end
          row :is_manuscript do |bibl|
            format_boolean_as_yes_no(bibl.is_manuscript)
          end
          row :is_collection do |bibl|
            format_boolean_as_yes_no(bibl.is_collection)
          end
          row :resource_type do |bibl|
            bibl.resource_type.to_s.titleize
          end
          row :genre do |bibl|
            bibl.genre.to_s.titleize
          end
          row ("Date Updated from VIRGO") do |bibl|
            bibl.date_external_update
          end
        end
      end
    end

    div :class => 'columns-none' do
      panel "Digital Library Information", :toggle => 'hide' do
        attributes_table_for bibl do
          row ("In Digital Library?") do |bibl|
            format_boolean_as_yes_no(bibl.in_dl?)
          end
          row :pid
          row :date_dl_ingest
          row :date_dl_update
          row :exemplar do |bibl|
            link_to "#{bibl.exemplar}", admin_master_files_path(:q => {:filename_eq => bibl.exemplar})
          end
          row :availability_policy
          row :indexing_scenario
          row :use_right
          row ("Discoverable?") do |bibl|
            format_boolean_as_yes_no(bibl.discoverability)
          end
          row :desc_metadata
          row :rels_ext
          row :solr
          row :dc
          row :rels_int
        end
      end
    end
    
    div :class => 'columns-none' do
      active_admin_comments
    end
  end

  sidebar "Related Information", :only => [:show, :edit] do
    attributes_table_for bibl do
      row ("Catalog Record") do |bibl|
        if bibl.in_catalog?
          div do
            link_to "VIRGO (Phsyical Record)", bibl.physical_virgo_url, :target => "_blank"
          end
        end
        if bibl.in_dl?
          div do
            link_to "VIRGO (Digital Record)", bibl.dl_virgo_url, :target => "_blank"
          end
        end
      end
      row "Digital Library" do |bibl|
        if bibl.in_dl?
          div do
            link_to "Fedora Object", bibl.fedora_url, :target => "_blank"
          end
        end
      end
      row :master_files do |bibl|
        link_to "#{bibl.master_files.size}", admin_master_files_path(:q => {:bibl_id_eq => bibl.id})
      end
      row :units do |bibl|
        link_to "#{bibl.units.size}", admin_units_path(:q => {:bibl_id_eq => bibl.id})
      end
      row :orders do |bibl|
        link_to "#{bibl.orders.size}", admin_orders_path(:q => {:bibls_id_eq => bibl.id})
      end
      row :customers do |bibl|
        link_to "#{bibl.customers.size}", admin_customers_path(:q => {:bibls_id_eq => bibl.id})
      end
      row :automation_messages do |bibl|
        link_to "#{bibl.automation_messages.size}", admin_automation_messages_path(:q => {:messagable_id_eq => bibl.id, :messagable_type_eq => "Bibl" })
      end
      row :components do |bibl|
        link_to "#{bibl.components.size}", admin_components_path(:q => {:bibls_id_eq => bibl.id})
      end
      row "Agencies Requesting Resource" do |bibl|
        bibl.agencies.uniq.sort_by(&:name).each {|agency|
          div do 
            link_to "#{agency.name}", admin_agency_path(agency)
          end
        } unless bibl.agencies.empty?
      end
      row "Legacy Identifiers" do |bibl|
        bibl.legacy_identifiers.each {|li|
          div do
            link_to "#{li.description} (#{li.legacy_identifier})", admin_legacy_identifier_path(li)
          end
        } unless bibl.legacy_identifiers.empty?
      end      
    end
  end

  sidebar "Digital Library Workflow", :only => [:show] do 
    div :class => 'workflow_button' do button_to "Update All XML Datastreams", update_metadata_admin_bibl_path(:datastream => 'allxml'), :method => :put end
    div :class => 'workflow_button' do button_to "Update Dublin Core", update_metadata_admin_bibl_path(:datastream => 'dc_metadata'), :method => :put end
    div :class => 'workflow_button' do button_to "Update Descriptive Metadata", update_metadata_admin_bibl_path(:datastream => 'desc_metadata'), :method => :put end
    div :class => 'workflow_button' do button_to "Update Relationships", update_metadata_admin_bibl_path(:datastream => 'rels_ext'), :method => :put end
    div :class => 'workflow_button' do button_to "Update Index Record", update_metadata_admin_bibl_path(:datastream => 'solr_doc'), :method => :put end
  end

  form :partial => "form"

  collection_action :external_lookup

  member_action :update_metadata, :method => :put do 
    Bibl.find(params[:id]).update_metadata(params[:datastream])
    redirect_to :back, :notice => "#{params[:datastream]} is being updated."
  end

  action_item :only => [:edit, :new] do
    link_to "Get Metadata From VIRGO", external_lookup_admin_bibls_path, :class => 'bibl_update_button', :method => :get, :remote => true
  end

  controller do
    # Only cache the index view if it is the base index_url (i.e. /bibls) and is devoid of either params[:page] or params[:q].  
    # The absence of these params values ensures it is the base url.
    caches_action :index, :unless => Proc.new { |c| c.params.include?(:page) || c.params.include?(:q) }
    caches_action :show
    cache_sweeper :bibls_sweeper

    #-----------------------------------------------------------------------------
    # Methods relating to updating Bibl records with metadata from an external
    # source, namely U.Va. Library catalog / Blacklight
    #-----------------------------------------------------------------------------
    # Looks up (via Ajax request) a record in the external metadata source (U.Va.
    # Library catalog / Blacklight) based on external-record-ID and populates the
    # HTML form fields on the page with corresponding values from the external
    # metadata record.
    def external_lookup
      # look up catalog ID (passed as a parameter) in external metadata source,
      # getting back a Bibl object with the values from the external source
      begin
        # Note: The Bibl object (variable "bibl") here is just a convenient
        # carrier for the metadata values gleaned from the external metadata
        # record; it is a new Bibl object that never gets saved to the database.
        # (If the user chooses to save the new values to the database, the user
        # clicks the Update button in the GUI.)
        @bibl = Virgo.external_lookup(params[:catalog_key], params[:barcode])
      end
     
      respond_to do |format|
        format.js 
      end
    end
  end
end
