ActiveAdmin.register XmlMetadata do
   menu :parent => "Metadata"

   # strong paramters handling
   permit_params :title, :creator_name,
       :is_approved, :is_personal_item, :is_manuscript, :is_collection, :resource_type, :genre,
       :exemplar, :discoverability, :date_dl_ingest, :date_dl_update, :availability_policy_id,
       :collection_facet, :use_right_id, :indexing_scenario_id, :content, :schema

   config.clear_action_items!

   action_item :new, :only => :index do
      raw("<a href='/admin/xml_metadata/new'>New</a>") if !current_user.viewer?
   end

   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if !current_user.viewer?
   end
   action_item :delete, only: :show do
      link_to "Delete", resource_path,
      data: {:confirm => "Are you sure you want to delete this XML Metadata?"}, :method => :delete  if current_user.admin?
   end

   scope :all, :default => true
   scope :approved
   scope :not_approved
   scope :in_digital_library
   scope :not_in_digital_library

   # Filters ==================================================================
   #
   filter :id
   filter :title
   filter :pid
   filter :is_manuscript
   filter :use_right, :as => :select, label: 'Right Statement'
   filter :resource_type, :as => :select, :collection => Bibl::RESOURCE_TYPES
   filter :availability_policy
   filter :customers_id, :as => :numeric
   filter :orders_id, :as => :numeric
   filter :agencies_id, :as => :numeric
   filter :collection_facet, :as => :string

   # INDEX page ===============================================================
   #
   index :id => 'xml_metadata' do
      selectable_column
      column :title, :sortable => :title do |xml_metadata|
         truncate_words(xml_metadata.title, 25)
      end
      column :creator_name
      column :pid, :sortable => false
      column :schema, :sortable => true
      column ("Digital Library?") do |xml_metadata|
         div do
            format_boolean_as_yes_no(xml_metadata.in_dl?)
         end
         if xml_metadata.in_dl?
            div do
               link_to "VIRGO", xml_metadata.dl_virgo_url, :target => "_blank"
            end
         end
      end
      column :units, :class => 'sortable_short', :sortable => :units_count do |xml_metadata|
         link_to xml_metadata.units.count, admin_units_path(:q => {:xml_metadata_id_eq => xml_metadata.id})
      end
      column("Master Files") do |xml_metadata|
         link_to xml_metadata.master_files.count, admin_master_files_path(:q => {:xml_metadata_id_eq => xml_metadata.id})
      end
      column("Links") do |xml_metadata|
         div do
            link_to "Details", resource_path(xml_metadata), :class => "member_link view_link"
         end
         if !current_user.viewer?
            div do
               link_to I18n.t('active_admin.edit'), edit_resource_path(xml_metadata), :class => "member_link edit_link"
            end
         end
      end
   end

   # DETAIL Page ==============================================================
   #
   show :title => proc { |xml_metadata| truncate(xml_metadata.title, :length => 60) } do
      div :class => 'two-column' do
       panel "Digital Library Information"  do
         attributes_table_for xml_metadata do
           row ("In Digital Library?") do |xml_metadata|
             format_boolean_as_yes_no(xml_metadata.in_dl?)
           end
           row :pid
           row :date_dl_ingest
           row :date_dl_update
           row :exemplar do |xml_metadata|
             link_to "#{xml_metadata.exemplar}", admin_master_files_path(:q => {:filename_eq => xml_metadata.exemplar})
           end
           row('Right Statement'){ |r| r.use_right.name }
           row :availability_policy
           row :indexing_scenario
           row ("Discoverable?") do |xml_metadata|
             format_boolean_as_yes_no(xml_metadata.discoverability)
           end
           row :collection_facet
         end
       end
     end

     div :class => 'two-column' do
       panel "Administrative Information" do
         attributes_table_for xml_metadata do
           row :is_approved do |xml_metadata|
             format_boolean_as_yes_no(xml_metadata.is_approved)
           end
           row :is_personal_item do |xml_metadata|
             format_boolean_as_yes_no(xml_metadata.is_personal_item)
           end
           row :is_manuscript do |xml_metadata|
             format_boolean_as_yes_no(xml_metadata.is_manuscript)
           end
           row :is_collection do |xml_metadata|
             format_boolean_as_yes_no(xml_metadata.is_collection)
           end
           row :resource_type do |xml_metadata|
             xml_metadata.resource_type.to_s.titleize
           end
           row :genre do |xml_metadata|
             xml_metadata.genre.to_s.titleize
           end
           row ("Date Created") do |xml_metadata|
             xml_metadata.created_at
           end
         end
       end
     end

     div :class => 'columns-none' do
       panel "XML Metadata" do
           render 'xml_meta'
       end
    end
   end

   # EDIT page ================================================================
   #
   form :partial => "edit_xml"

   # Sidebars =================================================================
   #
   sidebar "Related Information", :only => [:show, :edit] do
     attributes_table_for xml_metadata do
       row ("Catalog Record") do |xml_metadata|
         if xml_metadata.in_dl?
           div do
             link_to "VIRGO (Digital Record)", xml_metadata.dl_virgo_url, :target => "_blank"
           end
         end
       end
       row :master_files do |xml_metadata|
         link_to "#{xml_metadata.master_files.count}", admin_master_files_path(:q => {:xml_metadata_id_eq => xml_metadata.id})
       end
       row :units do |xml_metadata|
         link_to "#{xml_metadata.units.size}", admin_units_path(:q => {:xml_metadata_id_eq => xml_metadata.id})
       end
       row :orders do |xml_metadata|
         link_to "#{xml_metadata.orders.count}", admin_orders_path(:q => {:xml_metadata_id_eq => xml_metadata.id}, :scope => :uniq )
       end
       row :customers do |xml_metadata|
         link_to "#{xml_metadata.customers.count}", admin_customers_path(:q => {:xml_metadata_id_eq => xml_metadata.id})
       end
       row "Agencies Requesting Resource" do |xml_metadata|
         raw(xml_metadata.agency_links)
       end
     end
   end

   sidebar "Digital Library Workflow", :only => [:show],  if: proc{ !current_user.viewer? } do
      if xml_metadata.in_dl?
         div :class => 'workflow_button' do button_to "Publish",
           publish_admin_bibl_path, :method => :put end
      else
         "No options available.  Object is not in DL."
      end
   end

   # ACTIONS ==================================================================
   #
   member_action :publish, :method => :put do
     xm = XmlMetadata.find(params[:id])
     xm.update_attribute(:date_dl_update, Time.now)
     logger.info "XML Metadata #{xm.id}:#{xm.pid} has been flagged for an update in the DL"
     redirect_to "/admin/xml_metadata/#{params[:id]}", :notice => "XML Metadata flagged for Publication"
   end
end
