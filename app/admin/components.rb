ActiveAdmin.register Component do
  menu :priority => 7

  scope :all, :default => true
  actions :all, :except => [:destroy]

  filter :id
  filter :ead_id_att
  filter :component_type
  filter :title
  filter :content_desc
  filter :date
  filter :pid
  filter :availability_policy
  filter :indexing_scenario

  index do
    column :id
    column :title
    column :date
    column("Description") {|component| component.content_desc }
    column("DL Ingest Date") do |component|
      format_date(component.date_dl_ingest)
    end
    column :exemplar do |component|
      if not component.exemplar.blank?
        exemplar_master_file = MasterFile.find_by_filename(component.exemplar)
        link_to image_tag(exemplar_master_file.link_to_static_thumbnail, :height => 125), "#{exemplar_master_file.link_to_static_thumbnail}", :rel => 'colorbox', :title => "#{exemplar_master_file.filename} (#{exemplar_master_file.title} #{exemplar_master_file.description})"
      else
        "No exemplar set."
      end
    end
    column :master_files do |component|
      link_to "#{component.master_files.size}", admin_master_files_path(:q => {:component_id_eq => component.id})
    end
    column("Links") do |component|
      div do
        link_to "Details", resource_path(component), :class => "member_link view_link"
      end
      div do
        link_to I18n.t('active_admin.edit'), edit_resource_path(component), :class => "member_link edit_link"
      end
    end
  end
  
  show :title => proc{|component| "#{truncate(component.name, :length => 60)}"} do
    div :class => 'two-column' do
      panel "General Information" do
        attributes_table_for component do
          row :id
          row :title
          row :content_desc
          row :date
          row :level
          row :label
          row :ead_id_att
          row :component_type
          row("Followed By") do |component| 
            if not component.followed_by_id.nil?
              link_to "#{component.followed_by_id}", admin_component_path(component.followed_by_id) 
            else
              "None"
            end
          end
        end
      end
    end
  
   div :class => 'two-column' do
      panel "Digital Library Information" do
        attributes_table_for component do
          row :pid
          row :date_dl_ingest
          row :date_dl_update
          row :exemplar do |component|
            if not component.exemplar.blank?
              component.exemplar.to_s
              mf = MasterFile.where(:filename => component.exemplar).first
              if mf.kind_of?(MasterFile)
                link_to image_tag(mf.link_to_static_thumbnail, :height => 125), "#{mf.link_to_static_thumbnail}", :rel => 'colorbox', :title => "#{mf.filename} #{mf.title} #{mf.description}"
              end
            #link_to "#{bibl.exemplar}", admin_master_files_path(:q => {:filename_eq => bibl.exemplar})
              #link_to image_tag(component.exemplar.link_to_static_thumbnail, :height => 125), "#{component.exemplar.link_to_static_thumbnail}", :rel => 'colorbox', :title => "#{component.exemplar.filename} (#{component.exemplar.title} #{component.exemplar.description})"
            else
              nil
            end
          end
          row :availability_policy
          row :indexing_scenario
          row :discoverability do |component|
            case component.discoverability
            when false
              "UNDISCOVERABLE"
            when true
              "VISIBLE"
            else
              "Unknown"
            end
          end
          row(:desc_metadata) {|component| 
            if component.desc_metadata
              pre :class => "no-whitespace" do 
                code :'data-language' => 'html' do
                  word_wrap(component.desc_metadata.to_s, :line_width => 80)
                end
              end
            end
          }
          row(:solr) {|component| truncate_words(component.solr)}
          row(:dc) {|component| truncate_words(component.dc)}
          row(:rels_ext) {|component| truncate_words(component.rels_ext)}
          row(:rels_int) {|component| truncate_words(component.rels_int)}
          row(:legacy_ead) {|component| 
            if component.legacy_ead
              pre :class => "no-whitespace code-window" do 
                div :class => "click-advice" do 
                  span :class => "click-advice" do "default text" end 
                  span do image_tag( 'zoom.png'  ) end
                end
                code :'data-language' => 'html' do
                  word_wrap(component.legacy_ead.to_s, :line_width => 80)
                end
              end
            end
          }
        end
      end
    end
    
    div :class => "columns-none" do
      if ! component.children.empty?
        panel "Child Component Information", :toggle => 'show' do
          table_for component.children.select(:id).select(:date).select(:title).select(:content_desc).select(:ancestry).select(:seq_number).order(:seq_number) do
            column "#", :seq_number
            column :id
            column :date
            column :title do |child| link_to "#{child.title}", admin_component_path(child.id) end
            column :content_desc do |child| link_to "#{child.content_desc.truncate(255)}", admin_component_path(child.id) end
            column :master_files do |child| link_to "#{child.descendant_master_file_count}", admin_master_files_path(:q => {:component_id_eq => child.id}) end
          end
        end
      else        
        panel "No Child Components"
      end
    end
    
    div :class => "columns-none" do
      if not component.master_files.empty?
      then
        panel "Master Files", :toggle => 'show' do
          table_for component.master_files do |mf|
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
            column ("Bibliographic Title") do |mf|
              link_to "#{mf.bibl_title}", admin_bibl_path(mf.bibl.id)
            end
            column("Thumbnail") do |mf|
              link_to image_tag(mf.link_to_static_thumbnail, :height => 125), "#{mf.link_to_static_thumbnail}", :rel => 'colorbox', :title => "#{mf.filename} (#{mf.title} #{mf.description})"
            end
            column("") do |mf|
              div do
                link_to "Details", admin_master_file_path(mf), :class => "member_link view_link"
              end
              div do
                link_to I18n.t('active_admin.edit'), edit_admin_master_file_path(mf), :class => "member_link edit_link"
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
        end
      else
        panel "No Master Files Directly Associated with this Component"
      end
    end   
  end # end show

  form do |f|
    f.inputs "General Information", :class => 'inputs two-column' do 
      f.input :id, :as => :string, :input_html => {:disabled => true}
      f.input :title, :as => :text, :input_html => {:rows => 2}
      f.input :content_desc, :input_html => {:rows => 5}
      f.input :date
      f.input :level, :as => :select, :collection => Component.select(:level).uniq.map(&:level), :include_blank => false
      f.input :label
      f.input :ead_id_att
      f.input :component_type
    end

    f.inputs "Digital Library Information", :class => 'inputs two-column' do 
      f.input :pid, :as => :string, :input_html => {:disabled => true}
      f.input :exemplar, :as => :select
      f.input :availability_policy
      f.input :indexing_scenario
      f.input :desc_metadata, :input_html => {:rows => 5}
      f.input :solr, :input_html => {:rows => 5}
      f.input :dc, :input_html => {:rows => 5}
      f.input :rels_ext, :input_html => {:rows => 5}
      f.input :rels_int, :input_html => {:rows => 5}
      f.input :legacy_ead, :input_html => {:rows => 5}
    end

    f.inputs :class => 'columns-none' do
      f.actions 
    end
  end
  
  sidebar "Related Information", :only => [:show] do
    attributes_table_for component do
      row :bibls do |component|
        link_to "#{component.bibls.size}", admin_bibls_path(:q => {:components_id_eq => component.id})
      end
      row :master_files do |component|
        link_to "#{component.master_files.size}", admin_master_files_path(:q => {:component_id_eq => component.id})
      end
      row :parent_component do |component|
        if not component.parent.nil?
          link_to "#{component.parent.name}", admin_component_path(component.parent.id)
        end
      end
      row :child_components do |component|
        if not component.children.empty?
          link_to "#{component.children.size}", admin_components_path(:q => {:parent_component_id_eq => component.id})
        end
      end
      row :automation_messages do |component|
        link_to "#{component.automation_messages_count}", admin_automation_messages_path(:q => {:messagable_id_eq => component.id, :messagable_type_eq => "Component" })
      end
      row "Digital Library" do |component|
        if component.exists_in_repo?
          link_to "Fedora", "#{FEDORA_REST_URL}/objects/#{component.pid}", :class => 'member_link', :target => "_blank"
        end
      end
    end
  end

  sidebar "Digital Library Workflow", :only => [:show] do 
    if component.exists_in_repo?
      div :class => 'workflow_button' do button_to "Update All XML Datastreams", update_metadata_admin_component_path(:datastream => 'allxml'), :method => :put end
      div :class => 'workflow_button' do button_to "Update Dublin Core", update_metadata_admin_component_path(:datastream => 'dc_metadata'), :method => :put end
      div :class => 'workflow_button' do button_to "Update Descriptive Metadata", update_metadata_admin_component_path(:datastream => 'desc_metadata'), :method => :put end
      div :class => 'workflow_button' do button_to "Update Relationships", update_metadata_admin_component_path(:datastream => 'rels_ext'), :method => :put end
      div :class => 'workflow_button' do button_to "Update Index Record", update_metadata_admin_component_path(:datastream => 'solr_doc'), :method => :put end
    else
      "No options available.  Object not yet ingested."
    end
  end

  sidebar "Solr Index", :only => [:show] do
    if component.in_dl?
      div :class => 'workflow_button' do button_to "Commit Records to Solr", update_all_solr_docs_admin_component_path, :user => StaffMember.find_by_computing_id(request.env['HTTP_REMOTE_USER'].to_s), :method => :get end
    end
  end

  action_item :only => :show do
    link_to("Previous", admin_component_path(component.new_previous)) unless component.new_previous.nil?
  end

  action_item :only => :show do
    link_to("Next", admin_component_path(component.new_next)) unless component.new_next.nil?
  end

  action_item :only => :show do
    link_to "Create iView Catalog", export_iview_admin_component_path, :method => :put
  end

  # member actions
  member_action :export_iview, :method => :put do
    Component.find(params[:id]).create_iview_xml
    redirect_to :back, :notice => "New Iview Catalog written to file system." 
  end

  member_action :update_metadata, :method => :put do 
    Component.find(params[:id]).update_metadata(params[:datastream])
    redirect_to :back, :notice => "#{params[:datastream]} is being updated."
  end

  member_action :update_all_solr_docs do
    message = ActiveSupport::JSON.encode( {:message => 'go'})
    publish :send_commit_to_solr, message
    flash[:notice] = "All Solr records have been committed to #{STAGING_SOLR_URL}."
    redirect_to :back
  end

  member_action :tree, :method => :get do
    respond_to do |format|
      format.json { render :formats => [:json], :partial => "tree", root: false, object: Component.find(params[:id]) }
    end
  end
  
  controller do
    # Only cache the index view if it is the base index_url (i.e. /components) and is devoid of either params[:page] or params[:q].  
    # The absence of these params values ensures it is the base url.
    caches_action :index, :unless => Proc.new { |c| c.params.include?(:page) || c.params.include?(:q) }
    caches_action :show
    cache_sweeper :components_sweeper
  end
end
