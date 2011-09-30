ActiveAdmin.register Bibl, :namespace => :patron do

  scope :all, :default => true
 
  show :title => proc { bibl.call_number } do
    panel "Master Files" do
      div :id => "master_files" do
        collection = bibl.master_files.page(params[:master_file_page])
        pagination_options = {:entry_name => MasterFile.model_name.human, :param_name => :master_file_page, :download_links => false}
        paginated_collection(collection, pagination_options) do
          table_options = {:id => 'master-files-table', :sortable => true, :class => "master_file_index_table", :i18n => MasterFile }
          table_for collection, table_options do
            column("ID") {|order| link_to "#{master_file.id}", admin_master_file_path(master_file)}
            column :filename
            column :title
            column :description
          end
        end
      end
    end
  end
end
