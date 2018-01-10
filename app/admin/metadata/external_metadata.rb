ActiveAdmin.register ExternalMetadata do
   menu :parent => "Metadata"
   config.batch_actions = false
   config.per_page = [30, 50, 100, 250]

   # strong paramters handling
   permit_params :title, :creator_name,
      :is_approved, :is_personal_item, :is_manuscript, :resource_type_id, :genre_id,
      :exemplar, :discoverability, :date_dl_ingest, :date_dl_update, :availability_policy_id,
      :collection_facet, :use_right_id, :dpla, :external_uri,
      :collection_id, :ocr_hint_id, :ocr_language_hint, :parent_metadata_id

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

         panel "External Metadata" do
            if as_info.nil?
               div do "Unable to connect with external metadata source" end
            else
               attributes_table_for external_metadata do
                  row("External System") do |xm|
                     xm.external_system
                  end
                  row("Repository") do |xm|
                     as_info[:repo]
                  end
                  row("Collection Title") do |xm|
                     as_info[:collection_title]
                  end
                  row("ID") do |xm|
                     as_info[:id]
                  end
                  row("Language") do |xm|
                     as_info[:language]
                  end
                  row("Dates") do |xm|
                     as_info[:dates]
                  end
                  row("Title") do |xm|
                     as_info[:title]
                  end
                  row("Level") do |xm|
                     as_info[:level]
                  end
                  row("Created By") do |xm|
                     as_info[:created_by]
                  end
                  row("Create Time") do |xm|
                     as_info[:create_time]
                  end
               end
            end
         end
      end

      div :class => 'two-column' do
         panel "Administrative Information" do
            attributes_table_for external_metadata do
               row("Collection ID") do |external_metadata|
                  external_metadata.collection_id
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

   # EDIT page ================================================================
   #
   form :partial => "/admin/metadata/external_metadata/edit"

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
               render partial: '/admin/metadata/common/children_links', locals: {map: map, parent_id: external_metadata.id}
            end
         end
      end
   end

   controller do
       before_action :get_as_metadata, only: [:show]
       def get_as_metadata
          begin
             # First, authenticate with the API. Necessary to call other methods
             url = "#{Settings.as_api_url}/users/#{Settings.as_user}/login"
             resp = RestClient.post url, {password: Settings.as_pass}
             json = JSON.parse(resp.body)
             as_hdr = {:content_type => :json, :accept => :json, :'X-ArchivesSpace-Session'=>json['session']}

             # Now get the AO and ancestor details
             url = "#{Settings.as_api_url}#{resource.external_uri}"
             ao_detail = RestClient.get url, as_hdr
             ao_json = JSON.parse(ao_detail.body)

             # build a data struct to represent the AS data
             @as_info = {
                title: ao_json['display_string'], created_by: ao_json['created_by'],
                create_time: ao_json['create_time'], level: ao_json['level'],
             }
             dates = ao_json['dates'].first
             if !dates.nil?
                @as_info[:dates] = dates['expression']
             end

             # find the top level container in the ancestors
             coll_json = nil
             ao_json['ancestors'].each do |anc|
                if anc['level'] == 'collection'
                   url = "#{Settings.as_api_url}#{anc['ref']}"
                   coll = RestClient.get url, as_hdr
                   coll_json = JSON.parse(coll.body)
                   break
                end
             end

             @as_info[:collection_title] = coll_json['finding_aid_title']
             @as_info[:id] = coll_json['id_0']
             @as_info[:language] = coll_json['language']
             uri = coll_json['collection_management']['parent']['ref']
             @as_info[:uri] = uri

             repo = coll_json['collection_management']['repository']['ref']
             url = "#{Settings.as_api_url}#{repo}"
             resp = RestClient.get url, as_hdr
             repo_detail = JSON.parse(resp.body)
             puts "======\n#{repo_detail}"
             @as_info[:repo] = repo_detail['name']
          rescue Exception => e
             logger.error "Unable to get AS info for #{resource.id}: #{e.to_s}"
             @as_info = nil
          end
          puts "====> GOT AS_INFO #{@as_info.to_json}"
       end

       before_action :get_tesseract_langs, only: [:edit, :new]
       def get_tesseract_langs
          # Get list of tesseract supported languages
          lang_str = `tesseract --list-langs 2>&1`

          # gives something like: List of available languages (107):\nafr\...
          # split off info and make array
          lang_str = lang_str.split(":")[1].strip
          @languages = lang_str.split("\n")
       end
    end
end
