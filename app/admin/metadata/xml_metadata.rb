ActiveAdmin.register XmlMetadata do
   menu :parent => "Metadata"

   # strong paramters handling
   permit_params :title, :creator_name,
       :is_approved, :is_personal_item, :is_manuscript, :is_collection, :resource_type, :genre,
       :exemplar, :discoverability, :date_dl_ingest, :date_dl_update, :availability_policy_id,
       :collection_facet, :use_right_id, :indexing_scenario_id, :desc_metadata, :dpla, :parent_bibl_id

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
   scope :dpla

   # Filters ==================================================================
   #
   filter :id
   filter :title
   filter :pid
   filter :dpla, :as => :select
   filter :is_manuscript
   filter :use_right, :as => :select, label: 'Right Statement'
   filter :resource_type, :as => :select, :collection => SirsiMetadata::RESOURCE_TYPES
   filter :availability_policy
   filter :orders_id, :as => :numeric
   filter :collection_facet, :as => :string

   # INDEX page ===============================================================
   #
   index :id => 'xml_metadata' do
      selectable_column
      column :id
      column :title, :sortable => :title do |xml_metadata|
         truncate_words(xml_metadata.title, 25)
      end
      column :creator_name
      column :pid, :sortable => false
      column ("Digital Library?") do |xml_metadata|
         div do
            format_boolean_as_yes_no(xml_metadata.in_dl?)
         end
      end
      column ("DPLA?") do |xml_metadata|
        format_boolean_as_yes_no(xml_metadata.dpla)
      end
      column :units, :class => 'sortable_short', :sortable => :units_count do |xml_metadata|
         link_to xml_metadata.units.count, admin_units_path(:q => {:metadata_id_eq => xml_metadata.id})
      end
      column("Master Files") do |xml_metadata|
         link_to xml_metadata.master_files.count, admin_master_files_path(:q => {:metadata_id_eq => xml_metadata.id})
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
           row :pid
           row ("In Digital Library?") do |xml_metadata|
             format_boolean_as_yes_no(xml_metadata.in_dl?)
           end
           row :dpla
           if xml_metadata.dpla
              row('Parent Metadata ID'){ |r| r.parent_bibl_id }
           end
           row :exemplar do |xml_metadata|
             link_to "#{xml_metadata.exemplar}", admin_master_files_path(:q => {:filename_eq => xml_metadata.exemplar})
           end
           row('Right Statement'){ |r| r.use_right.name }
           row :availability_policy
           row :indexing_scenario
           row ("Discoverable?") do |sirsi_metadata|
             format_boolean_as_yes_no(sirsi_metadata.discoverability)
           end
           row :collection_facet
           row :date_dl_ingest
           row :date_dl_update
         end
       end
     end

     div :class => 'two-column' do
       panel "Administrative Information" do
         attributes_table_for xml_metadata do
           row :id
           row "Approved?" do |xml_metadata|
             format_boolean_as_yes_no(xml_metadata.is_approved)
           end
           row "Personal item?" do |xml_metadata|
             format_boolean_as_yes_no(xml_metadata.is_personal_item)
           end
           row "Manuscript or unpublished item?" do |xml_metadata|
             format_boolean_as_yes_no(xml_metadata.is_manuscript)
           end
           row "Collection?" do |xml_metadata|
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
       row :master_files do |xml_metadata|
         link_to "#{xml_metadata.master_files.count}", admin_master_files_path(:q => {:metadata_id_eq => xml_metadata.id})
       end
       row :units do |xml_metadata|
         link_to "#{xml_metadata.units.size}", admin_units_path(:q => {:metadata_id_eq => xml_metadata.id})
       end
       row :orders do |xml_metadata|
         link_to "#{xml_metadata.orders.count}", admin_orders_path(:q => {:metadata_id_eq => xml_metadata.id}, :scope => :uniq )
       end
       row :customers do |xml_metadata|
         link_to "#{xml_metadata.customers.count}", admin_customers_path(:q => {:metadata_id_eq => xml_metadata.id})
       end
       row "Agencies Requesting Resource" do |xml_metadata|
         raw(xml_metadata.agency_links)
       end
       row("Collection Metadata Record") do |xml_metadata|
          if xml_metadata.parent
            if xml_metadata.parent.type == "SirsiMetadata"
               link_to "#{xml_metadata.parent.title}", "/admin/sirsi_metadata/#{xml_metadata.parent.id}"
            elsif xml_metadata.parent.type == "XmlMetadata"
               link_to "#{xml_metadata.parent.title}", "/admin/xml_metadata/#{xml_metadata.parent.id}"
            end
          end
       end
       row "child metadata records" do |xml_metadata|
          map = xml_metadata.typed_children
          render partial: 'children_links', locals: {map: map, parent_id: xml_metadata.id}
       end
     end
   end

   sidebar "Digital Library Workflow", :only => [:show],  if: proc{ !current_user.viewer? } do
      if xml_metadata.in_dl?
         div :class => 'workflow_button' do
            button_to "Publish","/admin/xml_metadata/#{xml_metadata.id}/publish", :method => :put end
      else
         "No options available.  Object is not in DL."
      end
   end

   # ACTIONS ==================================================================
   #
   collection_action :get_all

   member_action :publish, :method => :put do
     xm = XmlMetadata.find(params[:id])
     xm.update_attribute(:date_dl_update, Time.now)
     logger.info "XML Metadata #{xm.id}:#{xm.pid} has been flagged for an update in the DL"
     redirect_to "/admin/xml_metadata/#{params[:id]}", :notice => "XML Metadata flagged for Publication"
   end

   controller do
       before_filter :get_dpla_collection_records, only: [:edit]
       def get_dpla_collection_records
          @dpla_collection_records = [{id:0, title:"None"}]
          Metadata.where("id in (#{Settings.dpla_collection_records})").each do |r|
             @dpla_collection_records << {id:r.id, title:r.title}
          end
       end

       def get_all
         out = []
         XmlMetadata.all.order(id: :asc).each do |m|
           out << {id: m.id, title: "#{m.id}: #{m.title}"}
         end
         render json: out, status: :ok
       end
    end

end
