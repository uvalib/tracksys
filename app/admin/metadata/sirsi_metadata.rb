ActiveAdmin.register SirsiMetadata do
  menu :parent => "Metadata", :priority => 1
  config.per_page = [30, 50, 100, 250]

  # strong paramters handling
  permit_params :catalog_key, :barcode, :title, :creator_name, :call_number,
      :is_manuscript,
      :discoverability, :dpla, :date_dl_ingest, :date_dl_update, :availability_policy_id,
      :collection_facet, :use_right_id, :collection_id, :creator_death_date, :use_right_rationale,
      :ocr_hint_id, :ocr_language_hint, :parent_metadata_id, :preservation_tier_id

  # eager load to preven n+1 queries, and improve performance
  includes :checkouts

  actions :all
  config.clear_action_items!

  action_item :new, :only => :index do
     raw("<a href='/admin/sirsi_metadata/new'>New</a>") if !current_user.viewer? && !current_user.student?
  end

  action_item :checkout, only: :show do
     if !current_user.viewer? && !current_user.student? && !resource.checked_out?
        raw("<a href='/admin/sirsi_metadata/#{resource.id}/checkout' rel='nofollow' data-method='put'>Checkout Materials</a>")
     else
        raw("<a href='/admin/sirsi_metadata/#{resource.id}/checkin' rel='nofollow' data-method='put'>Return Materials</a>")
     end
  end
  action_item :edit, only: :show do
     link_to "Edit", edit_resource_path  if !current_user.viewer? && !current_user.student?
  end
  action_item :delete, only: :show do
     link_to "Delete", resource_path,
       data: {:confirm => "Are you sure you want to delete this metadata?"}, :method => :delete  if current_user.admin?
  end

  scope :all, :default => true
  scope :in_digital_library
  scope :not_in_digital_library
  scope :dpla
  scope :checked_out
  scope "In APTrust", :in_ap_trust

  filter :barcode_starts_with, label: "Barcode"
  filter :call_number_starts_with, label: "Call Number"
  filter :title_contains, label: "Title"
  filter :creator_name_starts_with, label: "Creator name"
  filter :catalog_key_starts_with, label: "Catalog key"
  filter :pid_starts_with, label: "PID"
  filter :collection_id_contains, label: "Collection ID"
  filter :is_manuscript
  filter :dpla, :as => :select
  filter :use_right, :as => :select, label: 'Right Statement'
  filter :preservation_tier, :as => :select
  filter :availability_policy
  filter :collection_facet, :as => :select, :collection=>CollectionFacet.all.order(name: :asc).map { |cf| [cf.name] }

  csv do
    column :id
    column :title
    column :creator_name
    column :call_number
    column("# of Images") {|sirsi_metadata| sirsi_metadata.master_files.count}
    column("In digital library?") {|sirsi_metadata| format_boolean_as_yes_no(sirsi_metadata.in_dl?)}
  end

  batch_action :checkout do |selection|
     SirsiMetadata.find(selection).each { |s| s.checkout }
     flash[:notice] = "#{selection.size} item(s) have been checked out to DigiServ."
     redirect_to "/admin/sirsi_metadata"
  end

  batch_action :return do |selection|
     SirsiMetadata.find(selection).each { |s| s.checkin }
     flash[:notice] = "#{selection.size} item(s) have been returned from DigiServ."
     redirect_to "/admin/sirsi_metadata"
  end


  index :id => 'sirsi_metadata' do
    selectable_column
    column :id
    column :title, :sortable => :title do |sirsi_metadata|
      truncate_words(sirsi_metadata.title, 25)
    end
    column :creator_name
    column :call_number
    column :catalog_key, :sortable => :catalog_key do |sirsi_metadata|
      div do
        sirsi_metadata.catalog_key
      end
      if sirsi_metadata.in_catalog?
        div do
          link_to "VIRGO", sirsi_metadata.physical_virgo_url, :target => "_blank"
        end
      end
    end
    column :barcode, :class => 'sortable_short'
    column ("Checked Out?") do |sirsi_metadata|
      format_boolean_as_yes_no(sirsi_metadata.checked_out?)
    end
    column ("Digital Library?") do |sirsi_metadata|
      div do
        format_boolean_as_yes_no(sirsi_metadata.in_dl?)
      end
    end
    column ("DPLA?") do |sirsi_metadata|
      format_boolean_as_yes_no(sirsi_metadata.dpla)
    end
    column :units, :class => 'sortable_short', :sortable => :units_count do |sirsi_metadata|
      link_to sirsi_metadata.units_count, admin_units_path(:q => {:metadata_id_eq => sirsi_metadata.id})
    end
    column("Master Files") do |sirsi_metadata|
      link_to sirsi_metadata.master_files.count, admin_master_files_path(:q => {:metadata_id_eq => sirsi_metadata.id})
    end
    column("Links") do |sirsi_metadata|
      div do
        link_to "Details", resource_path(sirsi_metadata), :class => "member_link view_link"
      end
      if !current_user.viewer? && !current_user.student?
         div do
           link_to I18n.t('active_admin.edit'), edit_resource_path(sirsi_metadata), :class => "member_link edit_link"
         end
      end
    end
  end

  show :title => proc { truncate(@sirsi_meta[:title], :length => 60) } do
     if sirsi_metadata.checked_out?
      div class: "columns-none checkout-notice" do
         "- Checked out on #{sirsi_metadata.last_checkout} -"
      end
    end
    div :class => 'two-column' do
      panel "Metadata Details" do
        render '/admin/metadata/sirsi_metadata/sirsi_meta'
      end
    end

    div :class => 'two-column' do
       panel "Digital Library Information", :toggle => 'show' do
         attributes_table_for sirsi_metadata do
           row :pid
           row ("In Digital Library?") do |sirsi_metadata|
             format_boolean_as_yes_no(sirsi_metadata.in_dl?)
           end
           row :dpla
           if sirsi_metadata.dpla
              row('QDC Generated') do |r|
                 render partial: '/admin/metadata/common/qdc_info', locals: {meta: r}
              end
           end
           row('Right Statement'){ |r| r.use_right.name }
           row('Rights Rationale'){ |r| r.use_right_rationale }
           row :creator_death_date
           row :availability_policy
           row ("Discoverable?") do |sirsi_metadata|
             format_boolean_as_yes_no(sirsi_metadata.discoverability)
           end
           row :collection_facet
           row :date_dl_ingest
           row :date_dl_update
         end
       end

       panel "Administrative Information", :toggle => 'show' do
        attributes_table_for sirsi_metadata do
          row "Manuscript or unpublished item?" do |sirsi_metadata|
            format_boolean_as_yes_no(sirsi_metadata.is_manuscript)
          end
          row :ocr_hint
          row :ocr_language_hint
          row ("Date Created") do |sirsi_metadata|
            sirsi_metadata.created_at
          end
          row ("Checked Out?") do |sirsi_metadata|
             render partial: "/admin/metadata/sirsi_metadata/checkout_log", locals: {metadata: sirsi_metadata}
          end
          row ("Preservation Tier") do |sm|
             if sm.preservation_tier.blank?
                "Undefined"
             else
                "#{sm.preservation_tier.name}: #{sm.preservation_tier.description}"
             end
          end
        end
      end
      if !sirsi_metadata.ap_trust_status.nil? && current_user.can_set_preservation?
         render partial: '/admin/metadata/common/aptrust_info', locals: {meta: sirsi_metadata}
      end
    end
    div id: "dimmer" do
      render partial: "/admin/common/viewer_modal"
    end
  end

  sidebar "Exemplar", :only => [:show],  if: proc{ sirsi_metadata.has_exemplar? } do
     div :style=>"text-align:center" do
      info = sirsi_metadata.exemplar_info(:medium)
      image_tag(
         info[:url], id: info[:id],
         class: "do-viewer-enabled",
         data: { page: info[:page], metadata_pid:sirsi_metadata.pid, curio_url: Settings.doviewer_url } )
     end
  end

  sidebar "Related Information", :only => [:show, :edit] do
    attributes_table_for sirsi_metadata do
      row ("Catalog Record") do |sirsi_metadata|
        if sirsi_metadata.in_catalog?
          div do
            link_to "VIRGO", sirsi_metadata.physical_virgo_url, :target => "_blank"
          end
        end
      end
      row :master_files do |sirsi_metadata|
        link_to "#{sirsi_metadata.master_files.count}", admin_master_files_path(:q => {:metadata_id_eq => sirsi_metadata.id})
      end
      row :units do |sirsi_metadata|
        link_to "#{sirsi_metadata.units.size}", admin_units_path(:q => {:metadata_id_eq => sirsi_metadata.id})
      end
      row :orders do |sirsi_metadata|
        link_to "#{sirsi_metadata.orders.count}", admin_orders_path(:q => {:sirsi_metadata_id_eq => sirsi_metadata.id}, :scope => :uniq )
      end
      row :customers do |sirsi_metadata|
        link_to "#{sirsi_metadata.customers.count}", admin_customers_path(:q => {:metadata_id_eq => sirsi_metadata.id})
      end
      row "Agencies Requesting Resource" do |sirsi_metadata|
        raw(sirsi_metadata.agency_links)
      end
      if !sirsi_metadata.parent.blank?
        row("Parent Metadata Record") do |sirsi_metadata|
          if sirsi_metadata.parent.type == "SirsiMetadata"
             link_to "#{sirsi_metadata.parent.title}", "/admin/sirsi_metadata/#{sirsi_metadata.parent.id}"
          elsif sirsi_metadata.parent.type == "XmlMetadata"
             link_to "#{sirsi_metadata.parent.title}", "/admin/xml_metadata/#{sirsi_metadata.parent.id}"
          end
        end
      end
      if sirsi_metadata.children.count > 0
        row "child metadata records" do |sirsi_metadata|
          map = sirsi_metadata.typed_children
          render partial: '/admin/metadata/common/children_links', locals: {map: map, parent_id: sirsi_metadata.id}
        end
      end
    end
  end

  sidebar "Digital Library Workflow", :only => [:show],  if: proc{ !current_user.viewer? && !current_user.student? } do
     if sirsi_metadata.in_dl?
        div :class => 'workflow_button' do
           button_to "Publish", "/admin/sirsi_metadata/#{sirsi_metadata.id}/publish", :method => :put
        end
     else
        "No options available.  Object is not in DL."
     end
  end

  form :partial => "/admin/metadata/sirsi_metadata/form"

  collection_action :external_lookup

   member_action :checkout, :method => :put do
      SirsiMetadata.find(params[:id]).checkout
      redirect_to "/admin/sirsi_metadata/#{params[:id]}", :notice => "Materials checked out to DigiServ."
   end
   member_action :checkin, :method => :put do
      SirsiMetadata.find(params[:id]).checkin
      redirect_to "/admin/sirsi_metadata/#{params[:id]}", :notice => "Materials returned from DigiServ."
   end

  # Flag for publication  overnight
  #
  member_action :publish, :method => :put do
    metadata = SirsiMetadata.find(params[:id])
    metadata.flag_for_publication

    logger.info "SirsiMetadata #{metadata.id} has been flagged for an update in the DL"
    redirect_to "/admin/sirsi_metadata/#{params[:id]}", :notice => "Item flagged for publication"
  end

   include ActionView::Helpers::TextHelper
   controller do
      before_action :get_sirsi, only: [:edit, :show]
      def get_sirsi
         @sirsi_meta = {catalog_key: resource.catalog_key, barcode: resource.barcode,
            title: resource.title, creator_name: resource.creator_name,
            call_number: resource.call_number
         }
         if !resource.catalog_key.blank? || !resource.barcode.blank?
            begin
               @sirsi_meta =  Virgo.external_lookup(resource.catalog_key, resource.barcode)
            rescue Exception=>e
               @sirsi_meta = { invalid: true, catalog_key: resource.catalog_key, barcode: resource.barcode }
            end
         end
         if !resource.collection_id.blank?
            @sirsi_meta[:collection_id] = resource.collection_id
         else
            resource.update(collection_id: @sirsi_meta[:collection_id])
         end
      end

      before_action :blank_sirsi, except: [:show,:edit ]
      def blank_sirsi
         @sirsi_meta = {catalog_key: '', barcode: '' }
      end

      def external_lookup
         # look up catalog ID (passed as a parameter) in external metadata source
         begin
            @sirsi_meta = Virgo.external_lookup(params[:catalog_key], params[:barcode])
            render json: @sirsi_meta, status: :ok
         rescue Exception=> e
            render json: {invalid: true, catalog_key: params[:catalog_key],
               barcode: params[:barcode], message: "No matching Sirsi record found"}, status: :bad_request
         end
      end

      def update
         if !params[:sirsi_metadata][:ocr_language_hint].nil?
            params[:sirsi_metadata][:ocr_language_hint].reject!(&:empty?)
            params[:sirsi_metadata][:ocr_language_hint] = params[:sirsi_metadata][:ocr_language_hint].join("+")
         else
            params[:sirsi_metadata][:ocr_language_hint] = ""
         end
         super
      end
   end
end
