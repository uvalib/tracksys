ActiveAdmin.register Bibl, :namespace => :patron do

  scope :all, :default => true

  index do
    column :id
    column :title
    column :call_number
    column :barcode
    column :catalog_id   
    column :master_files_count
    column "Actions" do |bibl|
      link_to "Master Files", "master_files?q%5Bbibl_id_eq%5D=#{bibl.id}&order=filename_asc"
     # link_to "Master Files", patron_master_file_path(MasterFile.find(bibl.master_files.map(&:id)))
    end
  end 

  show :title => proc { "#{bibl.call_number} - #{bibl.title}" } do
    panel "Master Files" do
      div :id => "master_files" do
        collection = bibl.master_files.page(params[:master_file_page])
        pagination_options = {:entry_name => MasterFile.model_name.human, :param_name => :master_file_page, :download_links => false}
        paginated_collection(collection, pagination_options) do
          table_options = {:id => 'master-files-table', :sortable => true, :class => "master_file_index_table", :i18n => MasterFile, :as => :grid }
          table_for collection, table_options do
            column :id
            column :filename
            column :title
            column :description
#            column "Actions" do |master_file.bibl|
#              link_to "View", admin_master_file_path(MasterFile.find(bibl.master_files.map(&:id)))
#            end
          end
        end
      end
    end
  end
end
