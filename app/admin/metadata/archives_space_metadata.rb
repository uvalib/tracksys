ActiveAdmin.register ArchivesSpaceMetadata do
   menu :parent => "Metadata", label: 'ArchivesSpace Metadata'

   config.clear_action_items!
   actions :index

   scope :all, :default => true
   scope :approved
   scope :not_approved
   scope :in_digital_library
   scope :not_in_digital_library

   # Filters ==================================================================
   #
   filter :id
   filter :title
   filter :pid
   filter :is_manuscript
   filter :use_right, :as => :select, label: 'Right Statement'
   filter :resource_type, :as => :select, :collection => SirsiMetadata::RESOURCE_TYPES
   filter :availability_policy
   filter :customers_id, :as => :numeric
   filter :orders_id, :as => :numeric
   filter :agencies_id, :as => :numeric
   filter :collection_facet, :as => :string

   # INDEX page ===============================================================
   #
   index :title=>"ArchivesSpace Metadata", :id => 'xml_metadata' do
      selectable_column
      column :title, :sortable => :title do |xml_metadata|
         truncate_words(xml_metadata.title, 25)
      end
      column :creator_name
      column :pid, :sortable => false
      column ("Digital Library?") do |xml_metadata|
         div do
            format_boolean_as_yes_no(xml_metadata.in_dl?)
         end
         if xml_metadata.in_dl?
            div do
               link_to "VIRGO", xml_metadata.dl_virgo_url, :target => "_blank"
            end
         end
      end
      column :units, :class => 'sortable_short', :sortable => :units_count do |xml_metadata|
         link_to xml_metadata.units.count, admin_units_path(:q => {:metadata_id_eq => xml_metadata.id})
      end
      column("Master Files") do |xml_metadata|
         link_to xml_metadata.master_files.count, admin_master_files_path(:q => {:metadata_id_eq => xml_metadata.id})
      end
      column("Links") do |xml_metadata|
         # div do
         #    link_to "Details", resource_path(xml_metadata), :class => "member_link view_link"
         # end
         # if !current_user.viewer?
         #    div do
         #       link_to I18n.t('active_admin.edit'), edit_resource_path(xml_metadata), :class => "member_link edit_link"
         #    end
         # end
      end
   end
end
