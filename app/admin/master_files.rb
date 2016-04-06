ActiveAdmin.register MasterFile do
  config.sort_order = 'filename_asc'

  menu :priority => 6

  scope :all, :show_count => true, :default => true
  scope :in_digital_library, :show_count => true
  scope :not_in_digital_library, :show_count => true

  config.clear_action_items!
  action_item only: :show do
     link_to "Edit", edit_resource_path  if !current_user.viewer?
     link_to "OCR", "/admin/ocr?mf=#{master_file.id}"  if !current_user.viewer?
  end

  batch_action :download_from_archive do |selection|
    MasterFile.find(selection).each {|s| s.get_from_stornext }
    flash[:notice] = "Master Files #{selection.join(", ")} are now being downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR}."
    redirect_to :back
  end

  filter :id
  filter :filename
  filter :title
  filter :description
  filter :transcription_text
  filter :desc_metadata
  filter :pid
  filter :md5, :label => "MD5 Checksum"
  filter :unit_id, :as => :numeric, :label => "Unit ID"
  filter :order_id, :as => :numeric, :label => "Order ID"
  filter :customer_id, :as => :numeric, :label => "Customer ID"
  filter :bibl_id, :as => :numeric, :label => "Bibl ID"
  filter :customer_last_name, :as => :string, :label => "Customer Last Name"
  filter :bibl_title, :as => :string, :label => "Bibl Title"
  filter :bibl_creator_name, :as => :string, :label => "Author"
  filter :bibl_call_number, :as => :string, :label => "Call Number"
  filter :bibl_barcode, :as => :string, :label => "Barcode"
  filter :bibl_catalog_key, :as => :string, :label => "Catalog Key"
  filter :academic_status, :as => :select
  filter :availability_policy
  filter :indexing_scenario
  filter :date_archived
  filter :date_dl_ingest
  filter :date_dl_update
  filter :agency, :as => :select
  filter :heard_about_service, :as => :select
  filter :heard_about_resource, :as => :select

  index :id => 'master_files' do
    selectable_column
    column :filename, :sortable => false
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
    column :pid, :sortable => false
    column ("Bibliographic Record") do |mf|
      div do
        link_to "#{mf.bibl_title}", admin_bibl_path("#{mf.bibl_id}")
      end
      div do
        mf.bibl_call_number
      end
    end
    column :unit
    column("Thumbnail") do |mf|
      link_to image_tag(mf.link_to_static_thumbnail, :height => 125), "#{mf.link_to_static_thumbnail}", :rel => 'colorbox', :title => "#{mf.filename} (#{mf.title} #{mf.description})"
    end
    column("") do |mf|
      div do
        link_to "Details", resource_path(mf), :class => "member_link view_link"
      end
      if !current_user.viewer?
         div do
           link_to I18n.t('active_admin.edit'), edit_resource_path(mf), :class => "member_link edit_link"
         end
         div do
            link_to "OCR", "/admin/ocr?mf=#{mf.id}"
         end
      end
      if mf.in_dl?
        div do
          link_to "Fedora", "#{FEDORA_REST_URL}/objects/#{mf.pid}", :class => 'member_link', :target => "_blank"
        end
      end
      if mf.date_archived
        div do
          link_to "Download", copy_from_archive_admin_master_file_path(mf.id), :method => :put
        end
      end
    end
  end

  show :title => proc {|mf| mf.filename } do
    div :class => 'two-column' do
      panel "General Information" do
        attributes_table_for master_file do
          row :filename
          row :title
          row :description
          row :date_archived do |master_file|
            format_date(master_file.date_archived)
          end
          row :intellectual_property_notes do |master_file|
            if master_file.creation_date or master_file.primary_author or master_file.creator_death_date
              "Event Creation Date: #{master_file.creation_date} ; Author: #{master_file.primary_author} ; Author Death Date: #{master_file.creator_death_date}"
            else
              "no data"
            end
          end
          row :transcription_text do |master_file|
            simple_format(master_file.transcription_text)
          end
        end
      end
    end

    div :class => 'two-column' do
      panel "Technical Information", :id => 'master_files' do
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

    div :class => 'columns-none', :toggle => 'hide' do
      panel "Digital Library Information", :id => 'master_files', :toggle => 'show' do
        attributes_table_for master_file do
          row :pid
          row :date_dl_ingest
          row :date_dl_update
          row :availability_policy
          row :indexing_scenario
          row :discoverability do |mf|
            case mf.discoverability
            when false
              "Not uniquely discoverable"
            when true
              "Uniquely discoverable"
            else
              "Unknown"
            end
          end
          row(:desc_metadata) {|master_file|
           if not master_file.desc_metadata.nil?
              div do
                link_to "Edit", "#inline_content", :class => "inline"
              end
              div :style => 'display:none' do
                div :id => 'inline_content' do
                  div "Open the following URL in your Oxygen XML Editor (cmd-U)"
                  div "#{TRACKSYS_URL}admin/master_files/#{master_file.id}/mods"
                end
              end
              div :id => "desc_meta_div" do
                span :class => "click-advice" do "click in the code window to expand/collapse display" end
                pre :id => "desc_meta", :class => "no-whitespace code-window" do
                  code :'data-language' => 'html' do
                    word_wrap(master_file.desc_metadata.to_s, :line_width => 80)
                  end
                end
              end
            end
          }
        end
      end
    end
  end

  form do |f|
    f.inputs "General Information", :class => 'panel three-column ' do
      f.input :filename
      f.input :title
      f.input :description, :as => :text, :input_html => { :rows => 3 }
      f.input :creation_date, :as => :text, :input_html => { :rows => 1 }
      f.input :primary_author, :as => :text, :input_html => { :rows => 1 }
      f.input :creator_death_date, :as => :string, :input_html => { :rows => 1 }
      f.input :date_archived, :as => :string, :input_html => {:class => :datepicker}
      f.input :transcription_text, :input_html => { :rows => 5 }
    end

    f.inputs "Technical Information", :class => 'three-column panel' do
      f.input :md5, :input_html => { :disabled => true }
      f.input :filesize, :as => :number
    end

    f.inputs "Related Information", :class => 'panel three-column' do
      f.input :unit_id, :as => :number
      f.input :component_id, :as => :number
    end

    f.inputs "Digital Library Information", :class => 'panel columns-none', :toggle => 'hide' do
      f.input :pid, :input_html => { :disabled => true }
      f.input :availability_policy
      f.input :indexing_scenario
      f.input :desc_metadata, :input_html => { :rows => 5 }
    end

    f.inputs :class => 'columns-none' do
      f.actions
    end
  end

  sidebar "Thumbnail", :only => [:show] do
    div do
      link_to image_tag(master_file.link_to_static_thumbnail, :height => 250), "#{master_file.link_to_static_thumbnail}", :rel => 'colorbox', :title => "#{master_file.filename} (#{master_file.title} #{master_file.description})"
    end
    div do
      button_to "Print Image", print_image_admin_master_file_path, :method => :put
    end
  end

  sidebar "Related Information", :only => [:show] do
    attributes_table_for master_file do
      row :unit do |master_file|
        link_to "##{master_file.unit.id}", admin_unit_path(master_file.unit.id)
      end
      row :bibl
      row :order do |master_file|
        link_to "##{master_file.order.id}", admin_order_path(master_file.order.id)
      end
      row :customer
      row :component do |master_file|
        if master_file.component
          link_to "#{master_file.component.name}", admin_component_path(master_file.component.id)
        end
      end
      row :workflows do |master_file|
        link_to "#{master_file.job_statuses_count}", admin_job_statuses_path(:q => {:originator_id_eq => master_file.id, :originator_type_eq => "MasterFile"})
      end
      row :agency
      row "Digital Library" do |master_file|
        if master_file.in_dl?
          link_to "Fedora", "#{FEDORA_REST_URL}/objects/#{master_file.pid}", :class => 'member_link', :target => "_blank"
        end
      end
      row "Legacy Identifiers" do |master_file|
       	master_file.legacy_identifiers.each {|li|
          div do
            link_to "#{li.description} (#{li.legacy_identifier})", admin_legacy_identifier_path(li)
          end
        } unless master_file.legacy_identifiers.empty?
      end
    end
  end

  sidebar "Digital Library Workflow", :only => [:show],  if: proc{ !current_user.viewer? } do
    if master_file.in_dl?
      div :class => 'workflow_button' do button_to "Update All Datastreams", update_metadata_admin_master_file_path(:datastream => 'all'), :method => :put end
      div :class => 'workflow_button' do button_to "Update All XML Datastreams", update_metadata_admin_master_file_path(:datastream => 'allxml'), :method => :put end
      div :class => 'workflow_button' do button_to "Update JPEG-2000", update_metadata_admin_master_file_path(:datastream => 'jp2k'), :method => :put end
      div :class => 'workflow_button' do button_to "Update Dublin Core", update_metadata_admin_master_file_path(:datastream => 'dc_metadata'), :method => :put end
      div :class => 'workflow_button' do button_to "Update Descriptive Metadata", update_metadata_admin_master_file_path(:datastream => 'desc_metadata'), :method => :put end
      div :class => 'workflow_button' do button_to "Update Relationships", update_metadata_admin_master_file_path(:datastream => 'rels_ext'), :method => :put end
      div :class => 'workflow_button' do button_to "Update Index Record", update_metadata_admin_master_file_path(:datastream => 'solr_doc'), :method => :put end
    else
      "No options available.  Object not yet ingested."
    end
  end

  action_item :only => :show do
    link_to("Previous", admin_master_file_path(master_file.previous)) unless master_file.previous.nil?
  end

  action_item :only => :show do
    link_to("Next", admin_master_file_path(master_file.next)) unless master_file.next.nil?
  end

  action_item :only => :show do
    if master_file.in_dl?
      if master_file.availability_policy_id == 1
        if master_file.discoverability
          link_to "Pin It", "http://pinterest.com/pin/create/button/?#{URI.encode_www_form("url" => "http://search.lib.virginia.edu/catalog/#{master_file.pid}/view", "media" => "http://fedoraproxy.lib.virginia.edu/fedora/get/#{master_file.pid}/djatoka:jp2SDef/getRegion?level=3", "description" => "#{master_file.title} from #{master_file.bibl_title} &#183; #{master_file.bibl_creator_name} &#183; #{master_file.bibl.year} &#183; Albert and Shirley Small Special Collections Library, University of Virginia.")}", :class => "pin-it-button", :'count-layout' => 'vertical'
        else
          link_to "Pin It", "http://pinterest.com/pin/create/button/?#{URI.encode_www_form("url" => "http://search.lib.virginia.edu/catalog/#{master_file.bibl.pid}/view?&page=#{master_file.pid}", "media" => "http://fedoraproxy.lib.virginia.edu/fedora/get/#{master_file.pid}/djatoka:jp2SDef/getRegion?level=3", "description" => "#{master_file.title} from #{master_file.bibl_title} &#183; #{master_file.bibl_creator_name} &#183; #{master_file.bibl.year} &#183; Albert and Shirley Small Special Collections Library, University of Virginia.")}", :class => "pin-it-button", :'count-layout' => 'vertical'
        end
      else
        "Cannot pin. UVA Only."
      end
    else
    end
  end

  action_item :only => :show do
    if master_file.date_archived
      link_to "Download", copy_from_archive_admin_master_file_path(master_file.id), :method => :put
    end
  end

  member_action :copy_from_archive, :method => :put do
    mf = MasterFile.find(params[:id])
    mf.get_from_stornext(current_user.computing_id)
    redirect_to :back, :notice => "Master File #{mf.filename} is now being downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR}."
  end

  member_action :print_image, :method => :put do
    mf = MasterFile.find(params[:id])
    pdf = Prawn::Document.new
    pdf.font "Times-Roman"
    pdf.image "#{Rails.root.to_s}/app/assets/images/lib_letterhead.jpg", :at => [pdf.bounds.width - 275, pdf.cursor + 5], :fit => [275, 275]
    pdf.font("#{Rails.root.to_s}/app/assets/fonts/PTF55F.ttf") do
      pdf.text "ALBERT AND SHIRLEY SMALL", :position => :left, :size => 18
      pdf.text "Special Collections Library", :position => :left, :size => 16
    end
    pdf.move_down 5
    pdf.text "Under 17USC, Section 107, this single copy was produced for the purposes of private study, scholarship, or research.   No further copies should be made. Copyright and other legal restrictions may apply. Additionally, this copy may not be donated to other repositories.", :align => :center, :style => :italic, :size => 8

    pdf.image File.join(PRODUCTION_MOUNT, "#{mf.link_to_static_thumbnail}"), :fit => [550, 550], :position => :center
    pdf.move_down 5

    pdf.text "<b>Citation:</b> <i>#{mf.bibl.get_citation}</i>", :inline_format => true
    pdf.move_down 2

    if mf.bibl.catalog_key
      pdf.text "<b>Catalog Record:</b> <i>#{mf.bibl.physical_virgo_url}</i>", :inline_format => true
      pdf.move_down 2
    end

    if mf.in_dl? and mf.availability_policy_id == 1
      pdf.text "<b>Online Access:</b>  <i>#{mf.link_to_dl_page_turner}</i>", :inline_format => true
      pdf.move_down 2
    end

    if mf.component
      text = String.new
      mf.component.path_ids.each {|component_id|
        c = Component.find(component_id)
        name_details = String.new
        if c.date
          name_details = "(#{c.component_type.name.titleize}) <i>#{c.name}.</i> #{c.date}  "
        else
          name_details = "(#{c.component_type.name.titleize}) <i>#{c.name}.</i>  "
        end
        text << name_details
      }
      pdf.text "<b>Manuscript Information:</b>  " + text, :inline_format => true
      pdf.move_down 2
    end

    pdf.text "<b>Page Title:</b> <i>#{mf.title}</i>", :inline_format => true
    pdf.move_down 2

    # Page numbering
    string = "#{mf.pid}, #{mf.filename}, Printed: #{Time.now.strftime("%Y-%m-%d")}"
    options = { :at => [pdf.bounds.right - 300, 0],
              :width => 300,
              :size => 8,
              :align => :right}
    pdf.number_pages string, options

    # pdf.text "<b>Identifiers:</b> <i>#{mf.pid} (Repository), #{mf.filename} (Filename)</i>", :inline_format => true
    send_data pdf.render, :filename => "#{mf.filename.gsub(/.tif/, '')}.pdf", :type => "application/pdf", :disposition => 'inline'
  end

  member_action :update_metadata, :method => :put do
    MasterFile.find(params[:id]).update_metadata(params[:datastream])
    redirect_to :back, :notice => "#{params[:datastream]} is being updated."
  end

  # Specified in routes.rb to return the XML partial mods.xml.erb
  member_action :mods do
    @master_file = MasterFile.find(params[:id])
    @page_title = "MODS Record for MasterFile ##{@master_file.id}"
    render template: "admin/master_files/mods.xml.erb"
  end

  member_action :solr do
    @master_file = MasterFile.find(params[:id])
  end

  controller do
   #  # Only cache the index view if it is the base index_url (i.e. /master_files) and is devoid of either params[:page] or params[:q].
   #  # The absence of these params values ensures it is the base url.
   #  caches_action :index, :unless => Proc.new { |c| c.params.include?(:page) || c.params.include?(:q) }
   #  caches_action :show
   #  cache_sweeper :master_files_sweeper

    def update
      if env["HTTP_USER_AGENT"] =~ /Oxygen/ && env["REQUEST_METHOD"] == "PUT"
        body = request.body.read
        params.merge!({"master_file" => {desc_metadata: body.strip}})
        update! do |format|
          format.xml { redirect_to root_url }
        end
        # update! {root_url}
        # redirect_to(:id => '558388', :controller => 'admin/master_files', :action => 'show', :format => 'xml')
      else
        update!
      end
    end
  end
end
