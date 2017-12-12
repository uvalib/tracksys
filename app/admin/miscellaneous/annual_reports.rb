ActiveAdmin.register_page "Annual Reports" do
   menu :parent => "Miscellaneous", if: proc{ current_user.admin? || current_user.supervisor? }

   content do
      render partial: '/admin/miscellaneous/annual_reports/report'
   end

   page_action :generate, method: :get do
      if params[:type] == "category"
         html = category_report(params[:year])
      else
         render json: {success: false, message: "Invalid report type"}, status: :bad_request
         return
      end

      render json: {success: true, html: html}
   end

   controller do
      def category_report(year)
         puts "CATEGORY #{year}"
         columns = [ 'Category', 'January', 'February', 'March', 'April', 'May', 'June', 'July',
            'August', 'September', 'October', 'November', 'December', '1st Quarter',
            '2nd Quarter', '3rd Quarter', '4th Quarter', 'Year-To-Date']

         submitted = {}
         delivered = {}

         ["date_request_submitted", "date_customer_notified"].each do |term|
            stats = submitted
            stats = delivered if term == "date_customer_notified"
            totals = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

            AcademicStatus.order(:name).each do |status|
               stats[status.name] = []

               # monthly orders submitted
               for i in 1..12 do
                  cnt = status.orders.where("#{term} between '#{year}-#{i}-01' and '#{year}-#{i}-31'").count
                  stats[status.name] << cnt
                  totals[i-1] += cnt
               end

               # quarterly orders submitted
               [1,4,7,10,12].each_with_index do |month,idx|
                  ed = "31"
                  if month == 12
                     sm = "01"
                     em = "12"
                  else
                     sm = "%02d" % month
                     em = "%02d" % (month + 2)
                     ed = "30" if month == 4 || month == 7
                  end
                  cnt = status.orders.where("#{term} between '#{year}-#{sm}-01' and '#{year}-#{em}-#{ed}'").count
                  stats[status.name] << cnt
                  totals[12+idx] += cnt
               end
            end
            stats["Total"] = totals
         end

         return render_to_string(partial: "/admin/miscellaneous/annual_reports/category",
            locals: {year: year, columns: columns, submitted: submitted, delivered: delivered} )
      end

      def orders_report(year)
         puts "ORDERS"
      end

      def agency_month(year)
         puts "MONTHLY AGENCY"
      end

      def agency_year(year)
         puts "YEAR TO DATE AGENCY"
      end

      def current_orders(year)
         puts "CURRENT ORDERS"
      end
   end
end
