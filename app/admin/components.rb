ActiveAdmin.register Component do
   #menu :priority => 7
   menu :parent => "Miscellaneous"

   # # strong paramters handling
   # permit_params :title, :content_desc, :date, :level, :label, :ead_id_att, :component_type_id,
   #    :pid, :exemplar, :desc_meta

   #scope :all, :default => true

   config.clear_action_items!
   config.batch_actions = false
   # action_item :new, :only => :index do
   #    raw("<a href='/admin/components/new'>New</a>") if current_user.admin?
   # end
   # action_item :edit, only: :show do
   #    link_to "Edit", edit_resource_path  if current_user.admin?
   # end

   filter :title_or_content_desc_contains, label: "Title / Description"
   filter :date_contains, label: "Date"
   filter :ead_id_att_contains , label: "EAD ID ATT"
   filter :pid_contains, label: "PID"
   filter :component_type

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
            exemplar_master_file = MasterFile.find_by(filename: component.exemplar)
            if exemplar_master_file.nil?
               "Exemplar not found"
            else
               link_to image_tag(exemplar_master_file.link_to_image(:small)),
                  "#{exemplar_master_file.link_to_image(:large)}", :rel => 'colorbox',
                  :title => "#{exemplar_master_file.filename} (#{exemplar_master_file.title} #{exemplar_master_file.description})"
            end
         else
            "No exemplar set."
         end
      end
      column :master_files do |component|
         link_to "#{component.master_files.count}", admin_master_files_path(:q => {:component_id_eq => component.id})
      end
      column("Links") do |component|
         div do
            link_to "Details", resource_path(component), :class => "member_link view_link"
         end
         # if current_user.admin?
         #    div do
         #       link_to I18n.t('active_admin.edit'), edit_resource_path(component), :class => "member_link edit_link"
         #    end
         # end
      end
   end

   show :title => proc{|component| "#{truncate(component.name, :length => 60)}"} do
      div :class => 'one-column' do
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

      div :class => 'one-column' do
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
                        link_to image_tag(mf.link_to_image(:small)),
                           "#{mf.link_to_image(:large)}", :rel => 'colorbox', :title => "#{mf.filename} #{mf.title} #{mf.description}"
                     end
                  else
                     nil
                  end
               end
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
               row(:desc_metadata) do |component|
                  if component.desc_metadata
                     div :id => "desc_meta_div" do
                        span :class => "click-advice" do
                           "click in the code window to expand/collapse display"
                        end
                        pre :id => "desc_meta", :class => "no-whitespace code-window" do
                           code :'data-language' => 'html' do
                              word_wrap(component.desc_metadata.to_s, :line_width => 80)
                           end
                        end
                     end
                  end
               end
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
                  column :title do |child|
                     link_to "#{child.title}", admin_component_path(child.id)
                  end
                  column :content_desc do |child|
                     if not child.content_desc.nil?
                        link_to "#{child.content_desc.truncate(255)}", admin_component_path(child.id)
                     else
                        nil
                     end
                  end
                  column :own_children do |child|
                     link_to "#{child.children.size}", admin_components_path(:q => {:parent_component_id_eq => child.id})
                  end
                  column :own_master_files do |child|
                     link_to "#{child.master_files.size}", admin_master_files_path(:q => {:component_id_eq => child.id})
                  end
                  column :descendant_master_files do |child|
                     "#{child.descendant_master_file_count}"
                  end
                  column :ancestry
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
                  column ("Metadata Record") do |mf|
                     link_to "#{mf.metadata.title}", "/admin/#{mf.metadata.url_fragment}/#{mf.metadata.id}"
                  end
                  column("Thumbnail") do |mf|
                     link_to image_tag(mf.link_to_image(:small)),
                        "#{mf.link_to_image(:large)}", :rel => 'colorbox', :title => "#{mf.filename} (#{mf.title} #{mf.description})"
                  end
                  column("") do |mf|
                     div do
                        link_to "Details", admin_master_file_path(mf), :class => "member_link view_link"
                     end
                     div do
                        link_to I18n.t('active_admin.edit'), edit_admin_master_file_path(mf), :class => "member_link edit_link"
                     end
                     if mf.date_archived
                        div do
                           link_to "Download", download_from_archive_admin_master_file_path(mf.id), :method => :get
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
      f.inputs "General Information", :class => 'inputs one-column' do
         f.input :id, :as => :string, :input_html => {:disabled => true}
         f.input :title, :as => :text, :input_html => {:rows => 2}
         f.input :content_desc, :input_html => {:rows => 5}
         f.input :date
         f.input :level, :as => :select, :collection => Component.select(:level).uniq.map(&:level), :include_blank => false
         f.input :label
         f.input :ead_id_att
         f.input :component_type
      end

      f.inputs "Digital Library Information", :class => 'inputs one-column' do
         f.input :pid, :as => :string, :input_html => {:disabled => true}
         f.input :exemplar, :as => :select
         f.input :desc_metadata, :input_html => {:rows => 5}
      end

      f.inputs :class => 'columns-none' do
         f.actions
      end
   end

   sidebar "Related Information", :only => [:show] do
      attributes_table_for component do
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
      end
   end

   action_item :previous, :only => :show do
      link_to("Previous", admin_component_path(component.new_previous)) unless component.new_previous.nil?
   end

   action_item :next, :only => :show do
      link_to("Next", admin_component_path(component.new_next)) unless component.new_next.nil?
   end

   action_item :create, :only => :show do
      link_to "Create iView Catalog", export_iview_admin_component_path, :method => :put
   end

   member_action :export_iview, :method => :put do
      Component.find(params[:id]).export_iview_xml
      redirect_to "/admin/components/#{params[:id]}", :notice => "New Iview Catalog written to file system."
   end

   member_action :tree, :method => :get do
      respond_to do |format|
         format.json { render :formats => [:json], :partial => "tree", root: false, object: Component.find(params[:id]) }
      end
   end
end
