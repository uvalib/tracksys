ActiveAdmin.register ExternalMetadata do
   menu :parent => "Metadata"
   config.batch_actions = false

   # strong paramters handling
   permit_params :title, :creator_name,
      :is_approved, :is_personal_item, :is_manuscript, :resource_type_id, :genre_id,
      :exemplar, :discoverability, :date_dl_ingest, :date_dl_update, :availability_policy_id,
      :collection_facet, :use_right_id, :dpla,
      :collection_id, :box_id, :folder_id, :ocr_hint_id, :ocr_language_hint, :parent_metadata_id

   config.clear_action_items!

   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if !current_user.viewer? && !current_user.student?
   end
   action_item :delete, only: :show do
      link_to "Delete", resource_path,
      data: {:confirm => "Are you sure you want to delete this External Metadata?"}, :method => :delete  if current_user.admin?
   end

   scope :all, :default => true
   scope :approved
   scope :not_approved
   scope :in_digital_library
   scope :not_in_digital_library

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
   filter :collection_facet, :as => :select, :collection=>CollectionFacet.all.order(name: :asc)

   # INDEX page ===============================================================
   #
   index :id => 'external_metadata' do
      selectable_column
      column :id
      column :title, :sortable => :title do |external_metadata|
         truncate_words(external_metadata.title, 25)
      end
      column :pid, :sortable => false
      column ("Digital Library?") do |external_metadata|
         div do
            format_boolean_as_yes_no(external_metadata.in_dl?)
         end
      end
      column ("DPLA?") do |external_metadata|
         format_boolean_as_yes_no(external_metadata.dpla)
      end
      column :units, :class => 'sortable_short', :sortable => :units_count do |external_metadata|
         if external_metadata.units.count == 0 && external_metadata.master_files.count == 1
            link_to "1", "/admin/units/#{external_metadata.master_files.first.unit.id}"
         else
            link_to external_metadata.units.count, admin_units_path(:q => {:metadata_id_eq => external_metadata.id})
         end
      end
      column("Master Files") do |external_metadata|
         if external_metadata.master_files.count == 1
            link_to "1", "/admin/master_files/#{external_metadata.master_files.first.id}"
         else
            link_to external_metadata.master_files.count, admin_master_files_path(:q => {:metadata_id_eq => external_metadata.id})
         end
      end
      column("Links") do |external_metadata|
         div do
            link_to "Details", resource_path(external_metadata), :class => "member_link view_link"
         end
         # if !current_user.viewer? && !current_user.student?
         #    div do
         #       link_to I18n.t('active_admin.edit'), edit_resource_path(external_metadata), :class => "member_link edit_link"
         #    end
         # end
      end
   end

   # DETAIL Page ==============================================================
   #
   show :title => proc { |external_metadata| truncate(external_metadata.title, :length => 60) } do
      div :class => 'two-column' do
         panel "Digital Library Information"  do
            attributes_table_for external_metadata do
               row :pid
               row ("In Digital Library?") do |external_metadata|
                  format_boolean_as_yes_no(external_metadata.in_dl?)
               end
               row :dpla
               row :exemplar do |external_metadata|
                  link_to "#{external_metadata.exemplar}", admin_master_files_path(:q => {:filename_eq => external_metadata.exemplar})
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
            attributes_table_for external_metadata do
               row("Collection ID") do |external_metadata|
                  external_metadata.collection_id
               end
               row ("Box Number") do |external_metadata|
                  external_metadata.box_id
               end
               row ("Folder Number") do |external_metadata|
                  external_metadata.folder_id
               end
               row "Approved?" do |external_metadata|
                  format_boolean_as_yes_no(external_metadata.is_approved)
               end
               row "Personal item?" do |external_metadata|
                  format_boolean_as_yes_no(external_metadata.is_personal_item)
               end
               row "Manuscript or unpublished item?" do |external_metadata|
                  format_boolean_as_yes_no(external_metadata.is_manuscript)
               end
               row :resource_type
               row :genre
               row :ocr_hint
               row :ocr_language_hint
               row ("Date Created") do |external_metadata|
                  external_metadata.created_at
               end
            end
         end
      end
   end

   # Sidebars =================================================================
   #
   sidebar "Related Information", :only => [:show, :edit] do
      attributes_table_for external_metadata do
         # If there is only one master file, link directy to it
         if external_metadata.master_files.count == 1
            row :master_file do |external_metadata|
               link_to "##{external_metadata.master_files.first.id}", "/admin/master_files/#{external_metadata.master_files.first.id}"
            end
         else
            row :master_files do |external_metadata|
               if external_metadata.master_files.count > 0
                  link_to "#{external_metadata.master_files.count}", admin_master_files_path(:q => {:metadata_id_eq => external_metadata.id})
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
         if external_metadata.units.count == 0 && external_metadata.master_files.count == 1
            unit = external_metadata.master_files.first.unit
            row :unit do |external_metadata|
               link_to "##{unit.id}", "/admin/units/#{unit.id}"
            end
            row :order do |external_metadata|
               link_to "##{unit.order.id}", "/admin/orders/#{unit.order.id}"
            end
         else
            # units exist; use them as normal
            row :units do |external_metadata|
               if external_metadata.units.count > 0
                  link_to "#{external_metadata.units.count}", admin_units_path(:q => {:metadata_id_eq => external_metadata.id})
               else
                  raw("<span class='empty'>Empty</span>")
               end
            end
            row :orders do |external_metadata|
               if external_metadata.orders.count > 0
                  link_to "#{external_metadata.orders.count}", admin_orders_path(:q => {:external_metadata_id_eq => external_metadata.id}, :scope => :uniq )
               else
                  raw("<span class='empty'>Empty</span>")
               end
            end
            if external_metadata.units.count > 0
               row :customers do |external_metadata|
                  link_to "#{external_metadata.customers.count}", admin_customers_path(:q => {:metadata_id_eq => external_metadata.id})
               end
               row "Agencies Requesting Resource" do |external_metadata|
                  raw(external_metadata.agency_links)
               end
            end
         end

         # metadata heirarchy display (if necessary)
         if external_metadata.parent
            row("Parent Metadata Record") do |external_metadata|
               if external_metadata.parent.type == "SirsiMetadata"
                  link_to "#{external_metadata.parent.title}", "/admin/sirsi_metadata/#{external_metadata.parent.id}"
               elsif external_metadata.parent.type == "XmlMetadata"
                  link_to "#{external_metadata.parent.title}", "/admin/external_metadata/#{external_metadata.parent.id}"
               end
            end
         end
         if !external_metadata.children.blank?
            row "child metadata records" do |external_metadata|
               map = external_metadata.typed_children
               render partial: 'children_links', locals: {map: map, parent_id: external_metadata.id}
            end
         end
      end
   end
end
