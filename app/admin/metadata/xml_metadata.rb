ActiveAdmin.register XmlMetadata do
   menu :parent => "Metadata", :priority => 2
   config.batch_actions = false
   config.per_page = [30, 50, 100, 250]

   # strong paramters handling
   permit_params :title, :creator_name,
      :is_personal_item, :is_manuscript,
      :date_dl_ingest, :date_dl_update, :availability_policy_id,
      :collection_facet, :use_right_id, :desc_metadata, :dpla, :creator_death_date,
      :collection_id, :ocr_hint_id, :ocr_language_hint, :parent_metadata_id, :use_right_rationale,
      :preservation_tier_id

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
   scope :in_digital_library
   scope :not_in_digital_library
   scope :dpla
   scope "In APTrust", :in_ap_trust

   # Filters ==================================================================
   #
   filter :title_contains, label: "Title"
   filter :pid_starts_with, label: "PID"
   filter :collection_id_contains, label: "Collection ID"
   filter :dpla, :as => :select
   filter :is_manuscript
   filter :use_right, :as => :select, label: 'Right Statement'
   filter :preservation_tier, :as => :select
   filter :availability_policy
   filter :desc_metadata_contains, label: "XML Metadata"
   filter :collection_facet, :as => :select, :collection=>CollectionFacet.all.order(name: :asc)

   # INDEX page ===============================================================
   #
   index :id => 'xml_metadata' do
      selectable_column
      column :id
      column :pid
      column :title, :sortable => :title do |xml_metadata|
         truncate_words(xml_metadata.title, 25)
      end
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
               row('Right Statement'){ |r| r.use_right.name }
               row('Rights Rationale'){ |r| r.use_right_rationale }
               row :creator_death_date
               row :availability_policy
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
               row "Personal item?" do |xml_metadata|
                  format_boolean_as_yes_no(xml_metadata.is_personal_item)
               end
               row "Manuscript or unpublished item?" do |xml_metadata|
                  format_boolean_as_yes_no(xml_metadata.is_manuscript)
               end
               row :ocr_hint
               row :ocr_language_hint
               row ("Date Created") do |xml_metadata|
                  xml_metadata.created_at
               end
               row ("Preservation Tier") do |sm|
                  if sm.preservation_tier.blank?
                     "Undefined"
                  else
                     "#{sm.preservation_tier.name}: #{sm.preservation_tier.description}"
                  end
               end
               row ("Version History") do |sm|
                  if sm.has_versions?
                     link_to "#{sm.metadata_versions.count}", "/admin/xml_metadata/#{sm.id}/versions"
                  else
                     "None"
                  end
               end
            end
         end
         if !xml_metadata.ap_trust_status.nil? && current_user.can_set_preservation?
            render partial: '/admin/metadata/common/aptrust_info', locals: {meta: xml_metadata}
         end
      end

      div :class => 'columns-none' do
         panel "XML Metadata" do
            render '/admin/metadata/xml_metadata/xml_meta'
         end
      end
      div id: "dimmer" do
         render partial: "/admin/common/viewer_modal"
      end
   end

   # EDIT page ================================================================
   #
   form :partial => "/admin/metadata/xml_metadata/edit_xml"

   # Sidebars =================================================================
   #
   sidebar "Exemplar", :only => [:show],  if: proc{ xml_metadata.has_exemplar? } do
      div :style=>"text-align:center" do
         info = xml_metadata.exemplar_info(:medium)
         image_tag(
            info[:url], id: info[:id],
            class: "do-viewer-enabled",
            data: { page: info[:page], metadata_pid:xml_metadata.pid, curio_url: Settings.doviewer_url } )
      end
   end

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
                  link_to "#{xml_metadata.parent.title}", "/admin/xml_metadata/#{xml_metadata.parent.id}"
               elsif xml_metadata.parent.type == "XmlMetadata"
                  link_to "#{xml_metadata.parent.title}", "/admin/xml_metadata/#{xml_metadata.parent.id}"
               end
            end
         end
         if !xml_metadata.children.blank?
            row "child metadata records" do |xml_metadata|
               map = xml_metadata.typed_children
               render partial: '/admin/metadata/common/children_links', locals: {map: map, parent_id: xml_metadata.id}
            end
         end
      end
   end

   sidebar "Supplemental Metadata", :only => [:show],  if: proc{ !xml_metadata.supplemental_system.nil?} do
      div do
         xml_metadata.supplemental_system.name
      end
      div do
         xml_metadata.supplemental_uri
      end
      div :class => 'workflow_button', style: "margin-top: 15px" do
         url = "#{xml_metadata.supplemental_system.public_url}#{xml_metadata.supplemental_uri}"
         raw("<a class='view-supplemental' href='#{url}' target='_blank'>View</a>")
      end
   end

   sidebar "Digital Library Workflow", :only => [:show],  if: proc{ !current_user.viewer? && !current_user.student? } do
      if xml_metadata.in_dl? || xml_metadata.can_publish?
         div :class => 'workflow_button' do
            button_to "Publish", "/admin/xml_metadata/#{xml_metadata.id}/publish", :method => :put
         end
      else
         "No options available.  Object is not in DL."
      end
   end

   # ACTIONS ==================================================================
   #
   member_action :publish, :method => :put do
      metadata = XmlMetadata.find(params[:id])
      metadata.publish

      logger.info "XMLMetadata #{metadata.id} has been flagged for an update in the DL"
      redirect_to "/admin/xml_metadata/#{params[:id]}", :notice => "Item flagged for publication"
    end

   controller do
      def update
         # create a metadata version to track this change
         new_xml  = params[:xml_metadata][:desc_metadata]
         if MetadataVersion.has_changes? new_xml, resource.desc_metadata
            MetadataVersion.create(metadata: resource, staff_member: current_user,
               desc_metadata:  resource.desc_metadata, comment: params[:xml_metadata][:comment])
         end
         if !params[:xml_metadata][:ocr_language_hint].nil?
            params[:xml_metadata][:ocr_language_hint].reject!(&:empty?)
            params[:xml_metadata][:ocr_language_hint] = params[:xml_metadata][:ocr_language_hint].join("+")
         else
            params[:xml_metadata][:ocr_language_hint] = ""
         end
         super
      end

      before_action :get_ocr_languages, only: [:edit, :new]
      def get_ocr_languages
         begin
            resp = RestClient.get "#{Settings.jobs_url}/ocr/languages"
            @languages = resp.body.split(",")
         rescue => exception
            @languages = []
         end
      end
   end


    before_save do |metadata|
      new_xml  = params[:xml_metadata][:desc_metadata]
      xml = Nokogiri::XML( new_xml )
      xml.remove_namespaces!
      title_node = xml.xpath( "//titleInfo/title" ).first
      if !title_node.nil?
         title = title_node.text.strip
         metadata.title = title
      end
      creator = []
      first_node = xml.xpath("/mods/name").first
      if !first_node.nil?
         first_node.xpath("namePart").each do |node|
            creator << node.text.strip
         end
      end
      if !creator.blank?
         metadata.creator_name = creator.join(" ")
      end
   end
end
