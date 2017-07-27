ActiveAdmin.register XmlMetadata do
   menu :parent => "Metadata"
   config.batch_actions = false

   # strong paramters handling
   permit_params :title, :creator_name,
      :is_approved, :is_personal_item, :is_manuscript, :resource_type_id, :genre_id,
      :exemplar, :discoverability, :date_dl_ingest, :date_dl_update, :availability_policy_id,
      :collection_facet, :use_right_id, :desc_metadata, :dpla,
      :collection_id, :box_id, :folder_id, :ocr_hint_id, :parent_metadata_id

   config.clear_action_items!

   action_item :new, :only => :index do
      raw("<a href='/admin/xml_metadata/new'>New</a>") if !current_user.viewer?  && !current_user.student?
   end

   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if !current_user.viewer? && !current_user.student?
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
   filter :title_contains, label: "Title"
   filter :pid_starts_with, label: "PID"
   filter :collection_id_contains, label: "Collection ID"
   filter :box_id_contains, label: "Box Number"
   filter :folder_id_contains, label: "Folder Number"
   filter :dpla, :as => :select
   filter :is_manuscript
   filter :use_right, :as => :select, label: 'Right Statement'
   filter :resource_type, :as => :select, :collection => ResourceType.all.order(name: :asc)
   filter :genre, :as => :select, :collection=>Genre.all.order(name: :asc)
   filter :availability_policy
   filter :desc_metadata_contains, label: "XML Metadata"
   filter :collection_facet, :as => :select, :collection=>CollectionFacet.all.order(name: :asc)

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
         if xml_metadata.units.count == 0 && xml_metadata.master_files.count == 1
            link_to "1", "/admin/units/#{xml_metadata.master_files.first.unit.id}"
         else
            link_to xml_metadata.units.count, admin_units_path(:q => {:metadata_id_eq => xml_metadata.id})
         end
      end
      column("Master Files") do |xml_metadata|
         if xml_metadata.master_files.count == 1
            link_to "1", "/admin/master_files/#{xml_metadata.master_files.first.id}"
         else
            link_to xml_metadata.master_files.count, admin_master_files_path(:q => {:metadata_id_eq => xml_metadata.id})
         end
      end
      column("Links") do |xml_metadata|
         div do
            link_to "Details", resource_path(xml_metadata), :class => "member_link view_link"
         end
         if !current_user.viewer? && !current_user.student?
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
               row :exemplar do |xml_metadata|
                  link_to "#{xml_metadata.exemplar}", admin_master_files_path(:q => {:filename_eq => xml_metadata.exemplar})
               end
               row('Right Statement'){ |r| r.use_right.name }
               row :availability_policy
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
               row("Collection ID") do |xml_metadata|
                  xml_metadata.collection_id
               end
               row ("Box Number") do |xml_metadata|
                  xml_metadata.box_id
               end
               row ("Folder Number") do |xml_metadata|
                  xml_metadata.folder_id
               end
               row "Approved?" do |xml_metadata|
                  format_boolean_as_yes_no(xml_metadata.is_approved)
               end
               row "Personal item?" do |xml_metadata|
                  format_boolean_as_yes_no(xml_metadata.is_personal_item)
               end
               row "Manuscript or unpublished item?" do |xml_metadata|
                  format_boolean_as_yes_no(xml_metadata.is_manuscript)
               end
               row :resource_type
               row :genre
               row :ocr_hint
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
         # If there is only one master file, link directy to it
         if xml_metadata.master_files.count == 1
            row :master_file do |xml_metadata|
               link_to "##{xml_metadata.master_files.first.id}", "/admin/master_files/#{xml_metadata.master_files.first.id}"
            end
         else
            row :master_files do |xml_metadata|
               if xml_metadata.master_files.count > 0
                  link_to "#{xml_metadata.master_files.count}", admin_master_files_path(:q => {:metadata_id_eq => xml_metadata.id})
               else
                  raw("<span class='empty'>Empty</span>")
               end
            end
         end

         # No units but one master file is an indicator that descriptive XML
         # metadata was created specifically for the master file after initial ingest.
         # This is usually the case with image collections where each image has its own descriptive metadata.
         # In this case, there is no direct link from metadata to unit. Must find it by
         # going through the master file that this metadata describes
         if xml_metadata.units.count == 0 && xml_metadata.master_files.count == 1
            unit = xml_metadata.master_files.first.unit
            row :unit do |xml_metadata|
               link_to "##{unit.id}", "/admin/units/#{unit.id}"
            end
            row :order do |xml_metadata|
               link_to "##{unit.order.id}", "/admin/orders/#{unit.order.id}"
            end
         else
            # units exist; use them as normal
            row :units do |xml_metadata|
               if xml_metadata.units.count > 0
                  link_to "#{xml_metadata.units.count}", admin_units_path(:q => {:metadata_id_eq => xml_metadata.id})
               else
                  raw("<span class='empty'>Empty</span>")
               end
            end
            row :orders do |xml_metadata|
               if xml_metadata.orders.count > 0
                  link_to "#{xml_metadata.orders.count}", admin_orders_path(:q => {:xml_metadata_id_eq => xml_metadata.id}, :scope => :uniq )
               else
                  raw("<span class='empty'>Empty</span>")
               end
            end
            if xml_metadata.units.count > 0
               row :customers do |xml_metadata|
                  link_to "#{xml_metadata.customers.count}", admin_customers_path(:q => {:metadata_id_eq => xml_metadata.id})
               end
               row "Agencies Requesting Resource" do |xml_metadata|
                  raw(xml_metadata.agency_links)
               end
            end
         end

         # metadata heirarchy display (if necessary)
         if xml_metadata.parent
            row("Parent Metadata Record") do |xml_metadata|
               if xml_metadata.parent.type == "SirsiMetadata"
                  link_to "#{xml_metadata.parent.title}", "/admin/sirsi_metadata/#{xml_metadata.parent.id}"
               elsif xml_metadata.parent.type == "XmlMetadata"
                  link_to "#{xml_metadata.parent.title}", "/admin/xml_metadata/#{xml_metadata.parent.id}"
               end
            end
         end
         if !xml_metadata.children.blank?
            row "child metadata records" do |xml_metadata|
               map = xml_metadata.typed_children
               render partial: 'children_links', locals: {map: map, parent_id: xml_metadata.id}
            end
         end
      end
   end

   sidebar "Supplemental Metadata", :only => [:show],  if: proc{ !xml_metadata.supplemental_system.nil?} do
      attributes_table_for xml_metadata do
         row ("System") { |xml_metadata| xml_metadata.supplemental_system }
         row ("URI") { |xml_metadata| xml_metadata.supplemental_uri}
      end
      div :class => 'workflow_button' do
         raw("<a class='view-supplemental' href='#{Settings.archives_space_url}/#{xml_metadata.supplemental_uri}' target='_blank'>View</a>")
      end
   end

   sidebar "Digital Library Workflow", :only => [:show],  if: proc{ !current_user.viewer? && !current_user.student? && xml_metadata.master_files.count > 0} do
      if xml_metadata.in_dl?
         div :class => 'workflow_button' do
            button_to "Publish","/admin/xml_metadata/#{xml_metadata.id}/publish", :method => :put
         end
         div :class => 'workflow_button' do
            button_to "Publish to Virgo Test", "/admin/xml_metadata/#{xml_metadata.id}/test_publish", :method => :put
         end
      else
         div :class => 'workflow_button' do
            button_to "Publish to Digital Library Test", "/admin/xml_metadata/#{xml_metadata.id}/test_publish", :method => :put
         end
      end
   end

   # ACTIONS ==================================================================
   #

   # Flag for publication  overnight
   #
   member_action :publish, :method => :put do
      metadata = XmlMetadata.find(params[:id])
      metadata.flag_for_publication

      logger.info "XmlMetadata #{metadata.id} has been flagged for an update in the DL"
      redirect_to "/admin/xml_metadata/#{params[:id]}", :notice => "Item flagged for publication"
   end

   # Publish immediately to test instance of Virgo
   #
   member_action :test_publish, :method => :put do
      metadata = XmlMetadata.find(params[:id])
      metadata.publish_to_test
      logger.info "XmlMetadata #{metadata.pid} has been published to the test instance of Virgo"
      redirect_to "/admin/xml_metadata/#{params[:id]}", :notice => "Published to: #{Settings.test_virgo_url}/#{metadata.pid}"
   end
end
