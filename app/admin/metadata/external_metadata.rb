ActiveAdmin.register ExternalMetadata do
   menu :parent => "Metadata"
   config.batch_actions = false
   config.per_page = [30, 50, 100, 250]

   # strong paramters handling
   permit_params :title, :creator_name,
      :is_personal_item, :is_manuscript,
      :ocr_hint_id, :ocr_language_hint, :parent_metadata_id, :use_right_rationale,
      :external_uri, :external_system_id, :preservation_tier_id

   config.clear_action_items!

   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if !current_user.viewer? && !current_user.student?
   end
   action_item :delete, only: :show do
      link_to "Delete", resource_path,
      data: {:confirm => "Are you sure you want to delete this External Metadata?"}, :method => :delete  if current_user.admin?
   end

  action_item :new, :only => :index do
     raw("<a href='/admin/external_metadata/new'>New</a>") if !current_user.viewer?  && !current_user.student?
  end

   # Filters ==================================================================
   #
   filter :title_contains, label: "Title"
   filter :pid_starts_with, label: "PID"
   filter :external_system, :as => :select


   # INDEX page ===============================================================
   #
   index :id => 'external_metadata' do
      selectable_column
      column :id
      column :pid
      column :title, :sortable => :title do |external_metadata|
         truncate_words(external_metadata.title, 25)
      end
      column :external_system
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
         if !current_user.viewer? && !current_user.student?
            div do
               link_to I18n.t('active_admin.edit'), edit_resource_path(external_metadata), :class => "member_link edit_link"
            end
         end
      end
   end

   # DETAIL Page ==============================================================
   #
   show :title => proc { |external_metadata| truncate(external_metadata.title, :length => 60) } do
      div :class => 'two-column' do
         panel "External Metadata" do
            if external_metadata.external_system.name == "ArchivesSpace"
               render "/admin/metadata/external_metadata/as_panel", :context => self
            elsif external_metadata.external_system.name == "Apollo"
               render "/admin/metadata/external_metadata/apollo_panel", :context => self
            elsif external_metadata.external_system.name == "JSTOR Forum"
               render "/admin/metadata/external_metadata/jstor_panel", :context => self
            else
               div do "Unknown external system #{external_metadata.external_system.name}" end
            end
         end
      end

      div :class => 'two-column' do
         panel "Administrative Information" do
            attributes_table_for external_metadata do
               row :pid
               row :ocr_hint
               row :ocr_language_hint
               row ("Date Created") do |external_metadata|
                  external_metadata.created_at
               end
            end
         end
      end
      div id: "dimmer" do
         render partial: "/admin/common/viewer_modal"
       end
   end

   # EDIT page ================================================================
   #
   form :partial => "/admin/metadata/external_metadata/edit"

   # Sidebars =================================================================
   #
   sidebar "Exemplar", :only => [:show],  if: proc{ external_metadata.has_exemplar? } do
      div :style=>"text-align:center" do
         info = external_metadata.exemplar_info(:medium)
         image_tag(
            info[:url], id: info[:id],
            class: "do-viewer-enabled",
            data: { page: info[:page], metadata_pid:external_metadata.pid, curio_url: Settings.doviewer_url } )
      end
   end
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

   member_action :as_publish, :method => :post do
      begin
         metadata = ExternalMetadata.find( params[:id])
         PublishToAS.exec_now({metadata: metadata})
         render plain: "OK"
      rescue Exception => e
         render plain: "Publish Failed: "+e.to_s, status: :error
      end
   end

   controller do
      def create
         super
         if resource.external_system.name == "ArchivesSpace"
            auth = ArchivesSpace.get_auth_session()
            as = resource.external_system
            url = "#{as.public_url}#{resource.external_uri}"
            tgt_obj = ArchivesSpace.get_details(auth, url)
            title = tgt_obj['title']
            title = tgt_obj['display_string'] if title.blank?
            resource.update(title: title)
         end
      end

      def update
         if !params[:external_metadata][:ocr_language_hint].nil?
            params[:external_metadata][:ocr_language_hint].reject!(&:empty?)
            params[:external_metadata][:ocr_language_hint] = params[:external_metadata][:ocr_language_hint].join("+")
         else
            params[:external_metadata][:ocr_language_hint] = ""
         end
         super
         if resource.external_system.name == "ArchivesSpace"
            auth = ArchivesSpace.get_auth_session()
            as = resource.external_system
            url = "#{as.public_url}#{resource.external_uri}"
            tgt_obj = ArchivesSpace.get_details(auth, url)
            title = tgt_obj['title']
            title = tgt_obj['display_string'] if title.blank?
            resource.update(title: title)
         else
            resp = RestClient.get "#{resource.external_system.public_url}#{resource.external_uri}"
            json = JSON.parse(resp.body)
            item_data = json['item']['children']
            title = item_data.find{ |attr| attr['type']['name']=="title" }['value']
            resource.update(title: title)
         end
      end

      before_action :get_external_metadata, only: [:show]
      def get_external_metadata
         if resource.external_system.name == "ArchivesSpace"
            get_as_metadata()
         elsif resource.external_system.name == "Apollo"
            get_apollo_metadata()
         elsif resource.external_system.name == "JSTOR Forum"
            get_jstor_metadata()
         end
      end

      def get_jstor_metadata
         js = resource.external_system
         js_key = resource.master_files.first.filename.split(".").first 
         artstor_cookies = Jstor.start_public_session(js.public_url)
         js_cookies = Jstor.forum_login(js.api_url)
         forum_info = Jstor.forum_info(js.api_url, js_key, js_cookies)
         pub_info = Jstor.find_public_info(js.public_url, js_key, artstor_cookies)
         @js_info = {}
         @js_info[:url] = "#{js.public_url}#{resource.external_uri}"
         @js_info[:collection_title] = Metadata.find(resource.parent_metadata_id).title
         @js_info[:collection_url] = "#{js.public_url}/#/collection/1067"
         @js_info[:title] = pub_info[:title] 
         @js_info[:title] = forum_info[:title] if !forum_info.blank? && !forum_info[:title].blank?
         @js_info[:desc] = forum_info[:desc] if !forum_info.blank?
         @js_info[:creator] = forum_info[:creator] if !forum_info.blank?
         @js_info[:date] = pub_info[:date]
         @js_info[:width] = pub_info[:width]
         @js_info[:height] = pub_info[:height]
         @js_info[:id] = resource.external_uri.split("/").last
         @js_info[:ssid] = forum_info[:id] if !forum_info.blank?
      end

      def get_apollo_metadata
         begin
            apollo = resource.external_system
            resp = RestClient.get "#{apollo.public_url}#{resource.external_uri}"
            json = JSON.parse(resp.body)
            coll_data = json['collection']['children']
            item_data = json['item']['children']
            @apollo_info = {pid: json['collection']['pid'] }
            @apollo_info[:collection] = coll_data.find{ |attr| attr['type']['name']=="title" }['value']
            @apollo_info[:barcode] = coll_data.find{ |attr| attr['type']['name']=="barcode" }['value']
            @apollo_info[:catalog_key] = coll_data.find{ |attr| attr['type']['name']=="catalogKey" }['value']
            right = coll_data.find{ |attr| attr['type']['name']=="useRights" }
            @apollo_info[:rights] = right['value']
            @apollo_info[:rights_uri] = right['valueURI']
            @apollo_info[:item_pid] = json['item']['pid']
            @apollo_info[:item_type] = json['item']['type']['name']
            @apollo_info[:item_title] = item_data.find{ |attr| attr['type']['name']=="title" }['value']
         rescue Exception => e
            logger.error "Unable to get Apollo info for #{resource.id}: #{e.to_s}"
            @apollo_info = nil
            @apollo_error = e.to_s
         end
      end

      def get_as_metadata
         begin
            # First, authenticate with the API. Necessary to call other methods
            auth = ArchivesSpace.get_auth_session()
            as = resource.external_system
            url = "#{as.public_url}#{resource.external_uri}"
            tgt_obj = ArchivesSpace.get_details(auth, url)

            # build a data struct to represent the AS data
            title = tgt_obj['title']
            title = tgt_obj['display_string'] if title.blank?
            @as_info = {
               title: title, created_by: tgt_obj['created_by'],
               create_time: tgt_obj['create_time'], level: tgt_obj['level'],
               url: url
            }
            dates = tgt_obj['dates'].first
            if !dates.nil?
               @as_info[:dates] = dates['expression']
            end

            dobj = ArchivesSpace.get_digital_object(auth, tgt_obj, resource.pid )
            if !dobj.nil?
               @as_info[:published_at] = dobj[:created]
            end

            # pull repo ID from external URL and use it to lookup repo name:
            # /repositories/REPO_ID/resources/RES_ID
            repo_id = resource.external_uri.split("/")[2]
            repo_detail = ArchivesSpace.get_repository(auth, repo_id)
            @as_info[:repo] = repo_detail['name']


            if !tgt_obj['ancestors'].nil?
               anc = tgt_obj['ancestors'].last
               url = "#{as.api_url}#{anc['ref']}"
               coll = RestClient.get url, ArchivesSpace.auth_header(auth)
               coll_json = JSON.parse(coll.body)

               @as_info[:collection_title] = coll_json['finding_aid_title'].split("<num")[0]
               @as_info[:id] = coll_json['id_0']
               @as_info[:language] = coll_json['language']

            else
               @as_info[:collection_title] = tgt_obj['finding_aid_title'].split("<num")[0]
               @as_info[:id] = tgt_obj['id_0']
               @as_info[:language] = tgt_obj['language']
            end
         rescue Exception => e
            logger.error "Unable to get AS info for #{resource.id}: #{e.to_s}"
            @as_info = nil
         end
      end
   end
end
