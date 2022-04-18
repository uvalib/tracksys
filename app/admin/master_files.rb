ActiveAdmin.register MasterFile do
   menu :priority => 6
   config.per_page = [15, 30, 50]
   config.sort_order = "filename_asc"
   config.batch_actions = false

   # eager load to preven n+1 queries, and improve performance
   includes :metadata, :unit, :customer

   # strong paramters handling
   permit_params :filename, :title, :description, :creation_date, :primary_author,
      :date_archived, :md5, :filesize, :unit_id,
      :transcription_text, :pid, :metadata_id, :date_dl_update, :date_dl_ingest

   scope :all, :show_count => true, :default => true
   scope :in_digital_library, :show_count => true
   scope :not_in_digital_library, :show_count => true

   filter :filename_starts_with, label: "filename"
   filter :title_or_description_contains, label: "Title / Description"
   filter :description_contains, label: "Description"
   filter :tags_tag_contains, :label => "Tag"
   filter :metadata_call_number_starts_with, :label => "Call Number"
   filter :pid_starts_with, label: "PID"
   filter :agency, :as => :select, collection: Agency.pluck(:name, :id)
   filter :unit_id_equals, :label => "Unit ID"
   filter :order_id_equals, :label => "Order ID"
   filter :customer_id_equals, :label => "Customer ID"
   filter :customer_last_name_starts_with, :label => "Customer Last Name"
   filter :metadata_title_starts_with, :label => "Metadata Title"
   filter :metadata_creator_name_starts_with, :label => "Author"
   filter :locations_container_id_starts_with, :label => "Box"
   filter :locations_folder_id_starts_with, :label => "Folder"
   filter :unit_intended_use_id_equals, :label=>"Intended Use", :as=>:select, collection: IntendedUse.where("is_approved=1").pluck(:description, :id)
   filter :date_archived
   filter :date_dl_ingest
   filter :date_dl_update

   # Setup Action Items =======================================================
   config.clear_action_items!
   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if !current_user.viewer? && !current_user.student? && !master_file.deaccessioned?
   end

   action_item :pdf, :only => :show do
      if !master_file.metadata.nil? && !master_file.unit.date_archived.blank? && !master_file.deaccessioned?
         raw("<a href='#{Settings.pdf_url}/#{master_file.pid}' target='_blank'>Download PDF</a>")
      end
   end

   action_item :previous, :only => :show do
      link_to("Previous", admin_master_file_path(master_file.previous)) unless master_file.previous.nil?
   end

   action_item :next, :only => :show do
      link_to("Next", admin_master_file_path(master_file.next)) unless master_file.next.nil?
   end

   action_item :download, :only => :show do
      if master_file.date_archived && !master_file.deaccessioned?
         link_to "Download", download_from_archive_admin_master_file_path(master_file.id), :method => :get
      end
   end

   action_item :deaccession, :only => :show do
      if master_file.is_original? && master_file.reorders.size == 0 && current_user.can_deaccession? && !master_file.deaccessioned?
         link_to "Deaccession", "#", :class=>'deaccession', id: "deaccession-btn"
      end
   end

   action_item :pinterest, :only => :show do
      if  !master_file.deaccessioned?
         span :class=>"pinterest-wrapper" do
            if master_file.in_dl? && master_file.metadata.availability_policy_id == 1
               base_url = "https://www.pinterest.com/pin/create/button"
               url = "#{Settings.virgo_url}/#{master_file.metadata.pid}"
               media = master_file.link_to_image(:large)
               meta = master_file.metadata
               desc = "#{master_file.title} from #{meta.title} &#183; #{meta.creator_name}"
               desc << " &#183; Albert and Shirley Small Special Collections Library, University of Virginia."
               pin_img = "<img src='//assets.pinterest.com/images/pidgets/pinit_fg_en_round_red_32.png' />"
               pin_src_settings = "data-pin-description='#{desc}' data-pin-media='#{media}' data-pin-url='#{url}'"
               pin_type_settings = "data-pin-tall='true' data-pin-do='buttonPin' data-pin-round='true' data-pin-save='false'"
               raw("<a #{pin_src_settings} #{pin_type_settings} href='#{base_url}'>#{pin_img}</a>")
            end
         end
      end
   end

   # Index ====================================================================
   #
   index :id => 'master_files' do
      selectable_column
      column :id
      column :filename
      column :title do |mf|
         truncate_words(mf.title)
      end
      column :description do |mf|
         truncate_words(mf.description)
      end
      column ("Box") do |mf|
         mf.container_id
      end
      column :date_archived do |mf|
         format_date(mf.date_archived)
      end
      column :date_dl_ingest do |mf|
         format_date(mf.date_dl_ingest)
      end
      column ("Metadata Record") do |mf|
         if !mf.metadata.nil?
            div do
               link_to "#{truncate_words(mf.metadata_title, 75)}", "/admin/#{mf.metadata.url_fragment}/#{mf.metadata.id}"
            end
         end
      end
      column :unit
      column("Thumbnail") do |mf|
         render partial: "/admin/common/master_file_thumb", locals: {mf: mf}
      end
      column("") do |mf|
         div do
            link_to "Details", resource_path(mf), :class => "member_link view_link"
         end
         if !mf.metadata.nil? && !mf.unit.date_archived.blank? && !mf.deaccessioned?
            div do
               link_to "PDF", "#{Settings.pdf_url}/#{mf.pid}", target: "_blank"
            end
         end
         if !current_user.viewer? && !current_user.student? && !mf.deaccessioned?
            div do
               link_to I18n.t('active_admin.edit'), edit_resource_path(mf), :class => "member_link edit_link"
            end
         end
         if mf.date_archived && !mf.deaccessioned?
            div do
               link_to "Download", download_from_archive_admin_master_file_path(mf.id), :method => :get
            end
         end
      end
      render partial: "modals"
   end

   # Show =====================================================================
   #
   show :title => lambda{|mf|  mf.deaccessioned? ?  "#{mf.filename} : DEACCESSIONED" : mf.filename } do
      render partial: "pinit"
      render partial: "details"
   end

   # Edit ================================================================
   #
   form :partial => "edit"

   sidebar "Thumbnail", :only => [:show],  if: proc{ !master_file.deaccessioned? } do
      div :style=>"text-align:center" do
         mf_id = master_file.id
         uid = master_file.unit_id
         page = master_file.get_page_number()
         md_pid = nil
         md_pid = master_file.metadata.pid if !master_file.metadata.nil?
         image_tag(
            master_file.link_to_image(:medium),
            class: "do-viewer-enabled", id: mf_id,
            data: { page: page, metadata_pid: md_pid, unit: uid, curio_url: Settings.doviewer_url } )
      end
      if !current_user.viewer? && !current_user.student? && !master_file.deaccessioned? && master_file.ocr_candidate?
         div style: "margin-top:10px; text-align: center;" do
            span { link_to "OCR", "/admin/master_files/#{master_file.id}/ocr", method: :post, class: "mf-action-button" }
            span { link_to "Transcribe", "/admin/transcribe?mf=#{master_file.id}", class: "mf-action-button" }
         end
      end
   end

   sidebar "Related Information", :only => [:show] do
      attributes_table_for master_file do
         row "Metadata" do |unit|
            if !master_file.metadata.nil?
               url = "/admin/#{master_file.metadata.url_fragment}/#{master_file.metadata.id}"
               disp = "<a href='#{url}'><span>#{master_file.metadata.pid}<br/>#{master_file.metadata.title}</span></a>"
               raw( disp)
            end
         end
         row :unit do |master_file|
            link_to "##{master_file.unit.id}", admin_unit_path(master_file.unit.id)
         end
         row :order do |master_file|
            link_to "##{master_file.order.id}", admin_order_path(master_file.order.id)
         end
         row :component do |master_file|
            if master_file.component
               link_to "#{master_file.component.name}", admin_component_path(master_file.component.id)
            end
         end
         row :customer
         row :agency
      end
   end

   sidebar "Location", :only => [:show],  if: proc{ !master_file.location.nil? } do
      attributes_table_for master_file do
         row "Call Number" do |mf|
            mf.location.metadata.call_number
         end
         row "Type" do |mf|
            mf.location.container_type.name
         end
         row "Name" do |mf|
            mf.container_id
         end
         row "Folder" do |mf|
            mf.folder_id
         end
         if !master_file.location.notes.blank?
            row "Notes" do |mf|
               mf.location.notes
            end
         end
         row "Files In folder" do |mf|
            Location.find(mf.location.id).master_files.count
         end
         row "Units in Folder" do |mf|
            mf.location.units.count
         end
      end
   end

   member_action :ocr, :method => :post do
      mf = MasterFile.find(params[:id])
      OCR.master_file(mf)
      redirect_to "/admin/master_files/#{mf.id}",
         :notice => "OCR on master file #{mf.filename} has begun. Check the job status page for updates."
   end

   member_action :deaccession, :method => :post do
      mf = MasterFile.find(params[:id])
      begin
         DeaccessionMasterFile.exec_now({master_file: mf, user: current_user, note: params[:note] })
         render :nothing=>true
      rescue Exception=>e
         render :plain=> "Deaccession failed: #{e.message}", :status=>:error
      end
   end

   member_action :download_from_archive, :method => :get do
      mf = MasterFile.find(params[:id])
      RestClient.post "#{Settings.jobs_url}/units/#{params[:id]}/copy", {computeID: current_user.computing_id, filename: mf.filename}.to_json
      dest = File.join(Settings.production_mount, "from_archive", current_user.computing_id , mf.unit.directory, mf.filename )
      redirect_to "/admin/master_files/#{params[:id]}",
         :notice => "Master File downloaded to #{dest}."
   end

   member_action :set_exemplar, :method => :put do
      mf = MasterFile.find(params[:id])
      mf.unit.master_files.update_all(exemplar: false)
      mf.update(exemplar: true)
      redirect_to "/admin/units/#{mf.unit_id}"
   end

   member_action :add_new_tag, :method => :post do
      mf = MasterFile.find(params[:id])
      added = mf.add_new_tag( params[:tag])
      html = render_to_string partial: "tag", locals: {t: added}
      render json: {html: html}
   end
   member_action :add_tags, :method => :post do
      mf = MasterFile.find(params[:id])
      tags = params[:tags]
      html = ""
      mf.add_tags(tags).each do |t|
         html += render_to_string partial: "tag", locals: {t: t}
      end
      render json: {html: html}
   end
   member_action :remove_tag, :method => :post do
      mf = MasterFile.find(params[:id])
      tag = Tag.find(params[:tag])
      mf.tags.delete(tag)
      render plain: "OK"
   end

   member_action :save_transcription, :method => :post do
      mf = MasterFile.find(params[:id])
      src = mf.text_source
      if src.nil?
         # no prior text, set type to transcription
         src = 2
      elsif src == 0
         # Corrected OCR
         src = 1
      end
      if mf.update(transcription_text: params[:transcription], text_source: src)
         render plain: "OK"
      else
         render plain: mf.errors.full_messages.to_sentence, status: :internal_server_error
      end
   end

   # Location related actions =================================================
   #
   member_action :update_location, :method => :put do
      # Change the current location to a different (existing) one
      loc = Location.find_by(id: params[:location])
      if loc.nil?
         render plain: "Invalid location specified", status: :bad_request
      end
      mf = MasterFile.find(params[:id])
      mf.set_location(loc)
      render plain: "ok"
   end
   member_action :new_location, :method => :post do
      # Create a new location and set the current location it
      mf = MasterFile.find(params[:id])
      loc = Location.create!(container_type_id: params[:container_type], container_id: params[:container_id],
         folder_id: params[:folder_id], metadata_id: md.metadata.id)
      mf.set_location(loc)
      render plain: "ok"
   end

   csv do
     column :id
     column :pid
     column :filename
     column :filesize
     column :md5
     column :description
     column :title
     column("Date Archived") {|master_file| format_date(master_file.date_archived)}
     column("Date DL Ingest") {|master_file| format_date(master_file.date_dl_ingest)}
     column("Date DL Update") {|master_file| format_date(master_file.date_dl_update)}
     column :creation_date
     column :primary_author
     column("Intended Use") do |mf|
        if mf.unit.intended_use.nil?
           "N/A"
        else
           mf.unit.intended_use.description
        end
     end
   end

   controller do
      before_action :get_related_locations, only: [:edit]
      def get_related_locations
         @locations = nil
         return if resource.locations.blank?
         @locations = []
         Location.where(metadata_id: resource.location.metadata_id).includes(:container_type).each do |ct|
            @locations << {id:ct.id, container_type_id:ct.container_type_id, container_id:ct.container_id,
               folder_id:ct.folder_id, metadata_id:ct.metadata_id, has_folders: ct.container_type.has_folders}
         end
      end

      def update
         mf = MasterFile.find(params[:id])
         if !mf.location.nil?
            mf.location.update(
               folder_id: params[:master_file][:folder_id],
               container_id: params[:master_file][:container_id],
               container_type_id: params[:master_file][:container_type_id],
               notes: params[:master_file][:notes]
            )
         end
         mf.image_tech_meta.update(orientation: params[:master_file][:orientation])
         super
      end
   end
end
