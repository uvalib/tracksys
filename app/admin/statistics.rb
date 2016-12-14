ActiveAdmin.register_page "Statistics" do
   menu :priority => 2

   content do
      div :class => 'two-column' do
         panel "Image Statictics", :namespace => :admin, :priority => 1 do
            render partial: 'statistics', locals: { stat_group: "image"}
            render partial: 'image_query'
         end
         panel "Unit Statictics", :namespace => :admin, :priority => 3 do
            render partial: 'statistics', locals: { stat_group: "unit"}
            render partial: 'unit_query'
         end
      end

      div :class => 'two-column' do
         panel "Storage Statictics", :namespace => :admin, :priority => 2 do
            render partial: 'statistics', locals: { stat_group: "size"}
            render partial: 'size_query'
         end
         panel "Metadata Statictics", :namespace => :admin, :priority => 4 do
            render partial: 'statistics', locals: { stat_group: "metadata"}
            render partial: 'metadata_query'
         end
      end
   end

   page_action :query, method: :get do
      if params[:type] == "image"
         resp = Statistic.image_count( params[:location].to_sym, params[:start_date], params[:end_date])
         render text: resp, status: :ok and return
      end
      if params[:type] == "size"
         resp = Statistic.image_size( params[:location].to_sym, params[:start_date], params[:end_date])
         render text: resp, status: :ok and return
      end
      if params[:type] == "unit"
         resp = Statistic.unit_count(  params[:status].to_sym, params[:user].to_sym, params[:start_date], params[:end_date])
         render text: resp, status: :ok and return
      end
      if params[:type] == "metadata"
         resp = Statistic.metadata_count(  params[:metadata].to_sym, params[:location].to_sym, params[:start_date], params[:end_date])
         render text: resp, status: :ok and return
      end

      render :text=>"Invalid query type", :status=>:error
   end

   controller do
      before_filter :get_stats
      def get_stats
         @stats = Statistic.get
      end
   end
end
