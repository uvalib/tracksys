ActiveAdmin.register_page "Annual Reports" do
   menu :parent => "Miscellaneous", if: proc{ current_user.admin? || current_user.supervisor? }

   content do
      render partial: '/admin/miscellaneous/annual_reports/report'
   end

   page_action :generate, method: :get do
      if params[:type] == "category"
         html = category_report(params[:year])
      elsif params[:type] == "orders"
         html = orders_report(params[:year])
      elsif params[:type] == "agency_month"
         html = agency_month(params[:year])
      elsif params[:type] == "agency_year"
         html = agency_year(params[:year])
      elsif params[:type] == "current"
         html = current_orders
      else
         render json: {success: false, message: "Invalid report type"}, status: :bad_request
         return
      end

      render json: {success: true, html: html}
   end

   controller do
      def category_report(year)
         columns = [
            'Category', 'January', 'February', 'March', 'April', 'May', 'June', 'July',
            'August', 'September', 'October', 'November', 'December', '1st Quarter',
            '2nd Quarter', '3rd Quarter', '4th Quarter', 'Year-To-Date']

         submitted = {}
         delivered = {}

         ["date_request_submitted", "date_customer_notified"].each do |term|
            stats = submitted
            stats = delivered if term == "date_customer_notified"

            # each entry in totals array corresponds to columns entry from above
            totals = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

            AcademicStatus.order(:name).each do |status|
               stats[status.name] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
               # Get all dates for the year
               status.orders.where("cast(#{term} as date) between '#{year}-01-01' and '#{year}-12-31'").pluck(term).sort.each do |d|
                  # parse out month and tally up results
                  month = d.month
                  stats[status.name][month-1] += 1
                  totals[month-1] += 1

                  # Using parsed month, tally quarters counts
                  if month <= 3
                     # first quarter
                     stats[status.name][12] += 1
                     totals[12] += 1
                  elsif month <= 6
                     # second quarter
                     stats[status.name][13] += 1
                     totals[13] += 1
                  elsif month <= 9
                     # Third quarter
                     stats[status.name][14] += 1
                     totals[14] += 1
                  else
                     # fourth quarter
                     stats[status.name][15] += 1
                     totals[15] += 1
                  end

                  # year to date
                  stats[status.name][16] += 1
                  totals[16] += 1
               end
            end
            stats["Total"] = totals
         end

         return render_to_string(partial: "/admin/miscellaneous/annual_reports/category",
            locals: {year: year, columns: columns, submitted: submitted, delivered: delivered} )
      end

      def orders_report(year)
         columns = [ 'Statistic', 'January', 'February', 'March', 'April', 'May',
            'June', 'July', 'August', 'September', 'October', 'November',
            'December', 'Year-to-Date', 'Monthly Average']

         # define table with 9 arrays, one for each row in the work book. Start each row with a name.
         # the remaining data will be filled in below...
         data = [
            ['Orders Submitted'], ['Orders Delivered'], ['Orders Approved'],
            ['Orders Deferred'], ['Orders Canceled'], ['Units Archived'],
            ['Master Files Archived'], ['Size of Master Files Archived (GB)'], ['Units Delivered to DL'],
            ['Master Files Delivered to DL']
         ]

         # Append monthly stats to each row in the table structure defined above
         for i in 1..12 do
            data[0] << Order.where("date_request_submitted between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
            data[1] << Order.where("date_customer_notified between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
            data[2] << Order.where("date_order_approved between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
            data[3] << Order.where("date_deferred between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
            data[4] << Order.where("date_canceled between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
            data[5] << Unit.where("date_archived between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
            data[6] << MasterFile.where("master_files.date_archived between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
            arch_size = MasterFile.where("master_files.date_archived between '#{year}-#{i}-01' and '#{year}-#{i}-31'").map(&:filesize).inject(:+)
            if !arch_size.nil?
               data[7] << ( arch_size / 1024000000 )
            else
               data[7] << 0
            end
            data[8] << Unit.where("date_dl_deliverables_ready between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
            data[9] << MasterFile.where("date_dl_ingest between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
         end
         #
         #    # Year to Date Stats
         #    data[0] << Order.where("date_request_submitted between '#{year}-01-01' and '#{year}-12-31'").count
         #    data[1] << Order.where("date_customer_notified between '#{year}-01-01' and '#{year}-12-31'").count
         #    data[2] << Order.where("date_order_approved between '#{year}-01-01' and '#{year}-12-31'").count
         #    data[3] << Order.where("date_deferred between '#{year}-01-01' and '#{year}-12-31'").count
         #    data[4] << Order.where("date_canceled between '#{year}-01-01' and '#{year}-12-31'").count
         #    data[5] << Unit.where("date_archived between '#{year}-01-01' and '#{year}-12-31'").count
         #    data[6] << MasterFile.where("`master_files`.date_archived between '#{year}-01-01' and '#{year}-12-31'").count
         #    arch_size = MasterFile.where("`master_files`.date_archived between '#{year}-01-01' and '#{year}-12-31'").map(&:filesize).inject(:+)
         #    if !arch_size.nil?
         #       data[7] << ( arch_size / 1024000000 )
         #    else
         #       data[7] << 0
         #    end
         #    data[8] << Unit.where("date_dl_deliverables_ready between '#{year}-01-01' and '#{year}-12-31'").count
         #    data[9] << MasterFile.where("date_dl_ingest between '#{year}-01-01' and '#{year}-12-31'").count
         #
         #    # AVG Stats
         #    data[0] << data[0].last.to_i / query_month
         #    data[1] << data[1].last.to_i / query_month
         #    data[2] << data[2].last.to_i / query_month
         #    data[3] << data[3].last.to_i / query_month
         #    data[4] << data[4].last.to_i / query_month
         #    data[5] << data[5].last.to_i / query_month
         #    data[6] << data[6].last.to_i / query_month
         #    data[7] << data[7].last.to_i / query_month
         #    data[8] << data[8].last.to_i / query_month
         #    data[9] << data[9].last.to_i / query_month

         return render_to_string(partial: "/admin/miscellaneous/annual_reports/orders",
            locals: {year: year, columns: columns, data: data} )
      end

      def agency_month(year)
         columns = [
            'Agencies', 'Orders Submitted', 'Orders Deferred', 'Orders Approved', 'Orders Canceled',
            'Orders Archived', 'Orders Delivered', 'Units Delivered', 'Master Files Delivered',
            'Units Archived', 'Master Files Archived' ]

         data = {}
         for i in 1..12 do
            Agency.order(:name).each do |agency|
               r = [ agency.name ]
               r <<  agency.orders.where("date_request_submitted between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
               r <<  agency.orders.where("date_deferred between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
               r <<  agency.orders.where("date_order_approved between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
               r <<  agency.orders.where("date_canceled between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
               r <<  agency.orders.where("date_archiving_complete between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
               r <<  agency.orders.where("date_customer_notified between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
               r <<  agency.units.joins(:order).where("orders.date_customer_notified between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
               r <<  agency.master_files.joins(:order).where("orders.date_customer_notified between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
               r <<  agency.units.where("date_archived between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
               r <<  agency.master_files.where("master_files.date_archived between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
               sum = 0
               r.each { |v| sum+=v if v.is_a? Integer }

               if sum > 0
                  key = "#{i}/#{year}"
                  if !data.has_key? key
                     data[key] = []
                  end
                  data[key] << r
               end
            end
         end

         return render_to_string(partial: "/admin/miscellaneous/annual_reports/monthly_agency",
            locals: {year: year, columns: columns, data: data} )
      end

      def agency_year(year)
         return render_to_string(partial: "/admin/miscellaneous/annual_reports/agency_year",
            locals: {year: year} )
      end

      def current_orders
         data =  {'Orders Currently in Process': Order.in_process.count}
         data['Orders Currently Pending Approval'] = Order.awaiting_approval.count
         data['Orders Currently Deferred'] = Order.deferred.count
         return render_to_string(partial: "/admin/miscellaneous/annual_reports/current",
            locals: {today: Date.today, data: data} )
      end
   end
end
