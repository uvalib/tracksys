ActiveAdmin.register_page "Statistics" do
   menu :parent => "Miscellaneous", if: proc{ current_user.admin? || current_user.supervisor? }

   content do
      div :class => 'two-column' do
         panel "Image Statictics" do
            render partial: '/admin/miscellaneous/statistics/statistics', locals: { stat_group: "image"}
            render partial: '/admin/miscellaneous/statistics/image_query'
         end
         panel "Unit Statictics" do
            render partial: '/admin/miscellaneous/statistics/statistics', locals: { stat_group: "unit"}
            render partial: '/admin/miscellaneous/statistics/unit_query'
         end
         panel "Orders Processed Statictics" do
            render partial: '/admin/miscellaneous/statistics/processed_query'
         end
      end

      div :class => 'two-column' do
         panel "Storage Statictics" do
            render partial: '/admin/miscellaneous/statistics/statistics', locals: { stat_group: "size"}
            render partial: '/admin/miscellaneous/statistics/size_query'
         end
         panel "Metadata Statictics" do
            render partial: '/admin/miscellaneous/statistics/statistics', locals: { stat_group: "metadata"}
            render partial: '/admin/miscellaneous/statistics/metadata_query'
         end
         panel "Archived Item Statictics" do
            render partial: '/admin/miscellaneous/statistics/archived_query'
         end
      end
   end

   page_action :query, method: :get do
      if params[:type] == "processed"
         resp = Statistic.orders_processed_by_count( params[:user], params[:start_date], params[:end_date])
         render plain: resp, status: :ok and return
      end
      if params[:type] == "image"
         resp = Statistic.image_count( params[:location].to_sym, params[:start_date], params[:end_date])
         render plain: resp, status: :ok and return
      end
      if params[:type] == "size"
         resp = Statistic.image_size( params[:location].to_sym, params[:start_date], params[:end_date])
         render plain: resp, status: :ok and return
      end
      if params[:type] == "unit"
         resp = Statistic.unit_count(  params[:status].to_sym, params[:user].to_sym, params[:start_date], params[:end_date])
         render plain: resp, status: :ok and return
      end
      if params[:type] == "metadata"
         resp = Statistic.metadata_count(  params[:metadata].to_sym, params[:location].to_sym, params[:start_date], params[:end_date])
         render plain: resp, status: :ok and return
      end
      if params[:type] == "archived"
         if params[:category] == "bound"
            resp = archived_bound_volumes(  params[:start_date], params[:end_date])
            render plain: resp, status: :ok and return
         end
         if params[:category] == "mss"
            resp = archived_manuscript_pages(  params[:start_date], params[:end_date])
            render plain: resp, status: :ok and return
         end
         if params[:category] == "photo"
            resp = archived_photos(  params[:start_date], params[:end_date])
            render plain: resp, status: :ok and return
         end
      end

      render plain: "Invalid query type", :status=>:error
   end

   controller do
      before_action :get_stats
      def get_stats
         @stats = Statistic.get
         @users = StaffMember.where("role <= 1")   # admins and supervisors
      end

      def archived_manuscript_pages(start_date, end_date)
         date_clause = "f.date_archived >= '#{start_date}' and f.date_archived <= '#{end_date}'"
         bound_q = "select m.id from master_files f inner join metadata m on m.id = f.metadata_id"
         bound_q << " where f.title = 'Spine' and #{date_clause}"

         q = "select  count(f.id) from master_files f "
         q << "inner join metadata m on f.metadata_id = m.id where"
         q << "   (m.call_number like 'MSS%' or m.call_number like 'RG-%') and"

         # Skip back sides of pages
         q << "   f.title not like '%verso' and"

         # only take numbered pages, or pages that look like standard parts of MSS
         q << "   (f.title regexp '^[[:digit:]]+' or f.title like 'front%' or f.title like 'rear%'"
         q << "    or f.title like 'back%' or f.title like 'title%'"
         q << "    or f.title like 'table%' or f.title like 'blank%'"
         q << "    or f.title regexp '^(IX|IV|V?I{0,3})$') and"

         # No Bound stuff
         q << "   m.id not in (#{bound_q}) and "

         # No visual history stuff
         q << "   m.id != 3009 and"

         # only date rage specified
         q << "   #{date_clause}"

         return Statistic.connection.execute( q ).first.first.to_i
      end

      def archived_photos(start_date, end_date)
         date_clause = "f.date_archived >= '#{start_date}' and f.date_archived <= '#{end_date}'"
         q = "select count(f.id) from master_files f"
         q << " inner join metadata m on f.metadata_id = m.id"
         q << " inner join units u on u.id = f.unit_id inner join orders o on o.id = u.order_id"
         q << " inner join agencies a on a.id = o.agency_id"

         # Negatives orders and Fine arts agency
         q << " where ( o.id = 8126 or o.id = 8125 or agency_id = 37) and"

         # Not unbound sheets. Note the ugly null / no null grouping because
         # mysql like does not deal correctly with null data
         q << " (m.call_number is null or (m.call_number is not null and m.call_number not like 'RG-%'))"

         # in date range
         q << " and #{date_clause}"

         puts "====> #{q} <===="

         return Statistic.connection.execute( q ).first.first.to_i
      end

      def archived_bound_volumes(start_date, end_date)
         conditions = ["title='Spine'"]
         conditions << "date_archived >= '#{start_date}'"
         conditions << "date_archived <= '#{end_date}'"
         q = "select count(*) from master_files where "
         q << conditions.join(" and ")
         return Statistic.connection.execute( q ).first.first.to_i
      end
   end
end
