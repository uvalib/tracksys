ActiveAdmin.register MasterFile do
   menu :priority => 6
   config.per_page = 15
   config.sort_order = "filename_asc"
   config.batch_actions = false

   # eager load to preven n+1 queries, and improve performance
   includes :metadata, :unit, :customer

   # strong paramters handling
   permit_params :filename, :title, :description, :creation_date, :primary_author,
      :creator_death_date, :date_archived, :md5, :filesize, :unit_id,
      :transcription_text, :pid, :metadata_id

   scope :all, :show_count => true, :default => true
   scope :in_digital_library, :show_count => true
   scope :not_in_digital_library, :show_count => true


   filter :filename_starts_with, label: "filename"
   filter :title_or_description_contains, label: "Title / Description"
   filter :description_contains, label: "Description"
   filter :metadata_call_number_starts_with, :label => "Call Number"
   filter :pid_starts_with, label: "PID"
   filter :agency, :as => :select, collection: Agency.pluck(:name, :id)
   filter :unit_id_equals, :label => "Unit ID"
   filter :order_id_equals, :label => "Order ID"
   filter :customer_id_equals, :label => "Customer ID"
   filter :customer_last_name_starts_with, :label => "Customer Last Name"
   filter :metadata_title_starts_with, :label => "Metadata Title"
   filter :metadata_creator_name_starts_with, :label => "Author"
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

   action_item :ocr, only: :show do
      link_to "OCR", "/admin/ocr?mf=#{master_file.id}"  if !current_user.viewer? && !current_user.student? && !master_file.deaccessioned?
   end

   action_item :transcribe, only: :show do
      link_to "Transcribe", "/admin/transcribe?mf=#{master_file.id}"  if !current_user.viewer? && !current_user.student? && !master_file.deaccessioned?
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
               media = "#{Settings.iiif_url}/#{master_file.pid}/full/,640/0/default.jpg"
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
      column :date_archived do |mf|
         format_date(mf.date_archived)
      end
      column :date_dl_ingest do |mf|
         format_date(mf.date_dl_ingest)
      end
      column :pid
      column ("Metadata Record") do |mf|
         if !mf.metadata.nil?
            div do
               link_to "#{mf.metadata_title}", "/admin/#{mf.metadata.url_fragment}/#{mf.metadata.id}"
            end
         end
      end
      column :unit
      column("Thumbnail") do |mf|
         if mf.deaccessioned?
            span class: "deaccessioned" do "Deaccessioned" end
         else
            link_to image_tag(mf.link_to_image(:small)),
               "#{mf.link_to_image(:large)}", :rel => 'colorbox', :title => "#{mf.filename} (#{mf.title} #{mf.description})"
         end
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
            div do
               link_to "OCR", "/admin/ocr?mf=#{mf.id}"
            end
         end
         if mf.date_archived && !mf.deaccessioned?
            div do
               link_to "Download", download_from_archive_admin_master_file_path(mf.id), :method => :get
            end
         end
      end
   end

   # Show =====================================================================
   #
   show :title => lambda{|mf|  mf.deaccessioned? ?  "#{mf.filename} : DEACCESSIONED" : mf.filename } do
      render :partial=>"pinit"
      div :class => 'two-column' do
         if master_file.deaccessioned?
            panel "Deaccession Information" do
               attributes_table_for master_file do
                  row("Date Deaccessioned") do |master_file|
                     format_date(master_file.deaccessioned_at)
                  end
                  row :deaccessioned_by
                  row :deaccession_note do |master_file|
                    raw(master_file.deaccession_note.gsub(/\n/, '<br/>'))
                  end
               end
            end
         end
         panel "General Information" do
            attributes_table_for master_file do
               row :pid
               row :filename
               row :title
               row :description
               row :intellectual_property_notes do |master_file|
                  if master_file.creation_date or master_file.primary_author or master_file.creator_death_date
                     "Event Creation Date: #{master_file.creation_date} ; Author: #{master_file.primary_author} ; Author Death Date: #{master_file.creator_death_date}"
                  else
                     "no data"
                  end
               end
               row :date_archived do |master_file|
                  format_date(master_file.date_archived)
               end
               row :date_dl_ingest do |master_file|
                  format_date(master_file.date_dl_ingest )
               end
               row :date_dl_update do |master_file|
                  format_date(master_file.date_dl_update)
               end
            end
         end
      end
      render :partial=>"deaccession", :locals=>{ mf: master_file}

      div :class => 'two-column' do
         panel "Technical Information", :id => 'master_files', :toggle => 'show' do
            attributes_table_for master_file do
               row :md5
               row :filesize do |master_file|
                  "#{master_file.filesize / 1048576} MB"
               end
               if master_file.image_tech_meta
                  attributes_table_for master_file.image_tech_meta do
                     row :image_format
                     row("Height x Width"){|mf| "#{mf.height} x #{mf.width}"}
                     row :resolution
                     row :depth
                     row :compression
                     row :color_space
                     row :color_profile
                     row :equipment
                     row :model
                     row :iso
                     row :exposure_bias
                     row :exposure_time
                     row :aperture
                     row :focal_length
                     row :software
                  end
               end
            end
         end
      end

      if !master_file.transcription_text.blank?
         div :class => 'columns-none' do
            panel "Transcription Text", :toggle => 'show' do
               attributes_table_for master_file do
                  row("Text Source"){|mf| "#{mf.text_source.gsub(/_/, " ").titlecase}" if !mf.text_source.nil? }
               end
               div :class=>'mf-transcription' do
                  simple_format(master_file.transcription_text)
               end
            end
         end
      end
   end

   # EDIT page ================================================================
   form :partial => "edit"

   sidebar "Thumbnail", :only => [:show],  if: proc{ !master_file.deaccessioned? } do
      div :style=>"text-align:center" do
         link_to image_tag(master_file.link_to_image(:medium)),
            "#{master_file.link_to_image(:large)}",
            :rel => 'colorbox', :title => "#{master_file.filename} (#{master_file.title} #{master_file.description})"
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

   member_action :deaccession, :method => :post do
      mf = MasterFile.find(params[:id])
      begin
         DeaccessionMasterFile.exec_now({master_file: mf, user: current_user, note: params[:note] })
         render :nothing=>true
      rescue Exception=>e
         render :text=> "Deaccession failed: #{e.message}", :status=>:error
      end
   end

   member_action :download_from_archive, :method => :get do
      mf = MasterFile.find(params[:id])
      CopyArchivedFilesToProduction.exec_now( {:unit_id => mf.unit_id, :master_file_filename => mf.filename, :computing_id => current_user.computing_id })
      redirect_to "/admin/master_files/#{params[:id]}",
         :notice => "Master File downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR}/#{current_user.computing_id}/#{mf.filename}."
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
     column :creator_death_date
     column :creation_date
     column :primary_author
   end
end
