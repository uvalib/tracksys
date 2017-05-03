ActiveAdmin.register_page "Statistics" do
   menu :parent => "Miscellaneous", if: proc{ current_user.admin? || current_user.supervisor? }

   content do
      div :class => 'two-column' do
         panel "Image Statictics" do
            render partial: 'statistics', locals: { stat_group: "image"}
            render partial: 'image_query'
         end
         panel "Unit Statictics" do
            render partial: 'statistics', locals: { stat_group: "unit"}
            render partial: 'unit_query'
         end
         panel "Orders Processed Statictics" do
            render partial: 'processed_query'
         end
      end

      div :class => 'two-column' do
         panel "Storage Statictics" do
            render partial: 'statistics', locals: { stat_group: "size"}
            render partial: 'size_query'
         end
         panel "Metadata Statictics" do
            render partial: 'statistics', locals: { stat_group: "metadata"}
            render partial: 'metadata_query'
         end
      end
   end

   page_action :query, method: :get do
      if params[:type] == "processed"
         resp = Statistic.orders_processed_by_count( params[:user], params[:start_date], params[:end_date])
         render text: resp, status: :ok and return
      end
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
         @users = StaffMember.where("role <= 1")   # admins and supervisors
      end
   end
end
