class CreateStatsReport < BaseJob

   require 'spreadsheet'

   def set_originator(message)
      @status.update_attributes( :originator_type=>"StaffMember", :originator_id=>message[:user_id])
   end

   def do_workflow(message)
      today = Date.today
      query_year = message[:year]

      if query_year.to_s == today.year.to_s
         query_month = today.month
      else
         query_month = 12
      end

      # Create workbook and specify formatting
      book = Spreadsheet::Workbook.new
      heading_format = Spreadsheet::Format.new(:weight => :bold, :size => 16, :align => :merge)
      sub_heading_format = Spreadsheet::Format.new(:italic => 1)

      ######################################
      # Sheet 1
      ######################################
      sheet1 = book.create_worksheet
      sheet1.name = 'By Category'
      row_number = 0

      # Part I - Orders Submitted
      orders_submitted_heading_row = sheet1.row(row_number)
      for i in 1..17 do
         orders_submitted_heading_row.set_format(i, heading_format)
      end
      orders_submitted_heading_row[1] = "Orders Submitted #{query_year}"
      row_number += 1

      sheet1.row(row_number).replace [ 'Category', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', '1st Quarter', '2nd Quarter', '3rd Quarter', '4th Quarter', 'Year-To-Date']
      sheet1.row(row_number).set_format(i, sub_heading_format)
      row_number += 1

      # Submitted orders broken down by Academic Status
      AcademicStatus.order(:name).each do |status|
         sheet1.row(row_number).push "#{status.name}"
         # monthly orders submitted
         for i in 1..12 do
            sheet1.row(row_number).push status.orders.where("date_request_submitted between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
         end
         # quarterly orders submitted
         sheet1.row(row_number).push status.orders.where("date_request_submitted between '#{query_year}-01-01' and '#{query_year}-03-31'").count
         sheet1.row(row_number).push status.orders.where("date_request_submitted between '#{query_year}-04-01' and '#{query_year}-06-30'").count
         sheet1.row(row_number).push status.orders.where("date_request_submitted between '#{query_year}-07-01' and '#{query_year}-09-30'").count
         sheet1.row(row_number).push status.orders.where("date_request_submitted between '#{query_year}-10-01' and '#{query_year}-12-31'").count
         sheet1.row(row_number).push status.orders.where("date_request_submitted between '#{query_year}-01-01' and '#{query_year}-12-31'").count
         row_number += 1
      end

      # Totalling orders submitted
      sheet1.row(row_number).push "Total"
      for i in 1..12 do
         sheet1.row(row_number).push Order.where("date_request_submitted between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
      end
      sheet1.row(row_number).push Order.where("date_request_submitted between '#{query_year}-01-01' and '#{query_year}-03-31'").count
      sheet1.row(row_number).push Order.where("date_request_submitted between '#{query_year}-04-01' and '#{query_year}-06-30'").count
      sheet1.row(row_number).push Order.where("date_request_submitted between '#{query_year}-07-01' and '#{query_year}-09-30'").count
      sheet1.row(row_number).push Order.where("date_request_submitted between '#{query_year}-10-01' and '#{query_year}-12-31'").count
      sheet1.row(row_number).push Order.where("date_request_submitted between '#{query_year}-01-01' and '#{query_year}-12-31'").count
      row_number += 2 # Double increment to accomodate the next section

      # Part II - Orders Delivered
      orders_delivered_heading_row = sheet1.row(row_number)
      for i in 1..17 do
         orders_delivered_heading_row.set_format(i, heading_format)
      end
      orders_delivered_heading_row[1] = "Orders Delivered #{query_year}"
      row_number += 1

      sheet1.row(row_number).replace [ 'Category', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', '1st Quarter', '2nd Quarter', '3rd Quarter', '4th Quarter', 'Year-To-Date']
      sheet1.row(row_number).set_format(i, sub_heading_format)
      row_number += 1

      # Delivered Orders broken down by Academic Status
      AcademicStatus.order(:name).each do |status|
         sheet1.row(row_number).push "#{status.name}"
         # monthly orders submitted
         for i in 1..12 do
            sheet1.row(row_number).push status.orders.where("date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
         end
         # quarterly orders submitted
         sheet1.row(row_number).push status.orders.where("date_customer_notified between '#{query_year}-01-01' and '#{query_year}-03-31'").count
         sheet1.row(row_number).push status.orders.where("date_customer_notified between '#{query_year}-04-01' and '#{query_year}-06-30'").count
         sheet1.row(row_number).push status.orders.where("date_customer_notified between '#{query_year}-07-01' and '#{query_year}-09-30'").count
         sheet1.row(row_number).push status.orders.where("date_customer_notified between '#{query_year}-10-01' and '#{query_year}-12-31'").count
         sheet1.row(row_number).push status.orders.where("date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'").count
         row_number += 1
      end

      # Totalling orders submitted
      sheet1.row(row_number).push "Total"
      for i in 1..12 do
         sheet1.row(row_number).push Order.where("date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
      end
      sheet1.row(row_number).push Order.where("date_customer_notified between '#{query_year}-01-01' and '#{query_year}-03-31'").count
      sheet1.row(row_number).push Order.where("date_customer_notified between '#{query_year}-04-01' and '#{query_year}-06-30'").count
      sheet1.row(row_number).push Order.where("date_customer_notified between '#{query_year}-07-01' and '#{query_year}-09-30'").count
      sheet1.row(row_number).push Order.where("date_customer_notified between '#{query_year}-10-01' and '#{query_year}-12-31'").count
      sheet1.row(row_number).push Order.where("date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'").count


      ####################################
      # Sheet2
      ####################################
      sheet2 = book.create_worksheet
      sheet2.name = 'Orders & Units'

      orders_and_units_heading_row = sheet2.row(0)
      for i in 1..13 do
         orders_and_units_heading_row.set_format(i, heading_format)
      end
      orders_and_units_heading_row[1] = "Orders and Units Data - #{query_year}"

      # Sheet2 Sub-headings
      sheet2.row(1).replace [ 'Statistic', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', 'Year-To-Date', 'Average per month']

      for i in 0..15 do
         sheet2.row(1).set_format(i, sub_heading_format)
      end

      sheet2.row(2).push 'Orders Submitted'
      sheet2.row(3).push 'Orders Delivered'
      sheet2.row(4).push 'Orders Approved'
      sheet2.row(5).push 'Orders Deferred'
      sheet2.row(6).push 'Orders Canceled'
      sheet2.row(7).push 'Units Archived'
      sheet2.row(8).push 'Master Files Archived'
      sheet2.row(9).push 'Size of Master Files Archived (GB)'
      sheet2.row(10).push 'Units Delivered to DL'
      sheet2.row(11).push 'Master Files Delivered to DL'

      for i in 1..12 do
         # Total size of master files is for all units, so the emtpy integer variable can be decleared up front
         size_of_master_files_archived_month = 0

         # Orders Submitted
         number_of_orders_submitted_month = Order.where("date_request_submitted between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count

         # Orders Delivered
         number_of_orders_delivered_month = Order.where("date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count

         # Orders Approved
         number_of_orders_approved_month = Order.where("date_order_approved between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count

         # Orders Deferred
         number_of_orders_deferred_month = Order.where("date_deferred between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count

         # Orders Canceled
         number_of_orders_canceled_month = Order.where("date_canceled between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count

         # Units and Master Files Archived
         number_of_units_archived_month = Unit.where("date_archived between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
         number_of_master_files_archived_month = MasterFile.where("`master_files`.date_archived between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
         if number_of_master_files_archived_month > 0
            size_of_master_files_archived_month =  MasterFile.where("`master_files`.date_archived between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").map(&:filesize).inject(:+)
         end

         # Units and Master Files Delivered to DL
         number_of_units_delivered_to_dl_month = Unit.where("date_dl_deliverables_ready between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
         number_of_master_files_delivered_to_dl_month = MasterFile.where("date_dl_ingest between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count

         # Begin writing data for sheet2
         sheet2.row(2).push number_of_orders_submitted_month
         sheet2.row(3).push number_of_orders_delivered_month
         sheet2.row(4).push number_of_orders_approved_month
         sheet2.row(5).push number_of_orders_deferred_month
         sheet2.row(6).push number_of_orders_canceled_month
         sheet2.row(7).push number_of_units_archived_month
         sheet2.row(8).push number_of_master_files_archived_month
         sheet2.row(9).push size_of_master_files_archived_month / 1024000000 # convert the size from bytes to gigabytes
         sheet2.row(10).push number_of_units_delivered_to_dl_month
         sheet2.row(11).push number_of_master_files_delivered_to_dl_month
      end

      # Year to Date Stats
      number_of_orders_submitted_year_to_date = Order.where("date_request_submitted between '#{query_year}-01-01' and '#{query_year}-12-31'").count
      number_of_orders_delivered_year_to_date = Order.where("date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'").count
      number_of_orders_approved_year_to_date = Order.where("date_order_approved between '#{query_year}-01-01' and '#{query_year}-12-31'").count
      number_of_orders_deferred_year_to_date = Order.where("date_deferred between '#{query_year}-01-01' and '#{query_year}-12-31'").count
      number_of_orders_canceled_year_to_date = Order.where("date_canceled between '#{query_year}-01-01' and '#{query_year}-12-31'").count
      number_of_units_archived_year_to_date = Unit.where("date_archived between '#{query_year}-01-01' and '#{query_year}-12-31'").count
      number_of_master_files_archived_year_to_date = MasterFile.where("`master_files`.date_archived between '#{query_year}-01-01' and '#{query_year}-12-31'").count

      if number_of_master_files_archived_year_to_date > 0
         size_of_master_files_archived_year_to_date = MasterFile.where("`master_files`.date_archived between '#{query_year}-01-01' and '#{query_year}-12-31'").map(&:filesize).inject(:+)
      end

      number_of_units_delivered_to_dl_year_to_date = Unit.where("date_dl_deliverables_ready between '#{query_year}-01-01' and '#{query_year}-12-31'").count
      number_of_master_files_delivered_to_dl_year_to_date = MasterFile.where("date_dl_ingest between '#{query_year}-01-01' and '#{query_year}-12-31'").count

      sheet2.row(2).push number_of_orders_submitted_year_to_date, number_of_orders_submitted_year_to_date / query_month
      sheet2.row(3).push number_of_orders_delivered_year_to_date, number_of_orders_delivered_year_to_date / query_month
      sheet2.row(4).push number_of_orders_approved_year_to_date, number_of_orders_approved_year_to_date / query_month
      sheet2.row(5).push number_of_orders_deferred_year_to_date, number_of_orders_deferred_year_to_date / query_month
      sheet2.row(6).push number_of_orders_canceled_year_to_date, number_of_orders_canceled_year_to_date / query_month
      sheet2.row(7).push number_of_units_archived_year_to_date, number_of_units_archived_year_to_date / query_month
      sheet2.row(8).push number_of_master_files_archived_year_to_date, number_of_master_files_archived_year_to_date / query_month
      if !size_of_master_files_archived_year_to_date.nil?
         sheet2.row(9).push size_of_master_files_archived_year_to_date / 1024000000, (size_of_master_files_archived_year_to_date / 1024000000) / query_month
      end
      sheet2.row(10).push number_of_units_delivered_to_dl_year_to_date, number_of_units_delivered_to_dl_year_to_date / query_month
      sheet2.row(11).push number_of_master_files_delivered_to_dl_year_to_date, number_of_master_files_delivered_to_dl_year_to_date / query_month

      ####################################
      # Sheet 3 (By Agency Monthly Data)
      ####################################
      sheet3 = book.create_worksheet
      sheet3.name = 'By Agency (Monthly Data)'

      agency_month_heading_text = "Agency Orders By Month"
      agency_month_heading_row = sheet3.row(0)
      for j in 0..10 do
         agency_month_heading_row.set_format(j, heading_format)
      end
      agency_month_heading_row[0] = agency_month_heading_text

      sheet3_i = 1 #Start on row 1

      for i in 1..12 do
         month_text = "#{i}/#{query_year}"
         month_text_row = sheet3.row(sheet3_i)

         month_text_row[0] = month_text

         for x in 0..10 do
            month_text_row.set_format(x, heading_format)
         end

         sheet3_i = sheet3_i.next

         # Sheet3 Sub-headings
         sheet3.row(sheet3_i).replace [ 'Agencies', 'Orders Submitted', 'Orders Deferred', 'Orders Approved', 'Orders Canceled', 'Orders Archived', 'Orders Delivered', 'Units Delivered', 'Master Files Delivered', 'Units Archived', 'Master Files Archived' ]
         for k in 0..10 do
            sheet3.row(sheet3_i).set_format(k, sub_heading_format)
         end
         sheet3_i += 1

         Agency.order(:name).each do |agency|
            number_of_agency_orders_submitted_month = agency.orders.where("date_request_submitted between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
            number_of_agency_orders_deferred_month = agency.orders.where("date_deferred between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
            number_of_agency_orders_approved_month = agency.orders.where("date_order_approved between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
            number_of_agency_orders_canceled_month = agency.orders.where("date_canceled between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
            number_of_agency_orders_archived_month = agency.orders.where("date_archiving_complete between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
            number_of_agency_orders_delivered_month = agency.orders.where("date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
            number_of_agency_units_delivered_month = agency.units.joins(:order).where("`orders`.date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
            number_of_agency_units_archived_month = agency.units.where("date_archived between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
            number_of_agency_master_files_archived_month = agency.master_files.where("`master_files`.date_archived between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
            number_of_agency_master_files_delivered_month = agency.master_files.joins(:order).where("`orders`.date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count

            if number_of_agency_orders_submitted_month == 0 and number_of_agency_orders_deferred_month == 0 and number_of_agency_orders_approved_month == 0 and number_of_agency_orders_canceled_month == 0 and number_of_agency_orders_archived_month == 0 and number_of_agency_orders_delivered_month == 0 and number_of_agency_units_delivered_month == 0 and number_of_agency_units_archived_month == 0 and number_of_agency_master_files_archived_month == 0 and number_of_agency_master_files_delivered_month == 0
            else
               sheet3.row(sheet3_i).push agency.name, number_of_agency_orders_submitted_month, number_of_agency_orders_deferred_month, number_of_agency_orders_approved_month, number_of_agency_orders_canceled_month, number_of_agency_orders_archived_month, number_of_agency_orders_delivered_month, number_of_agency_units_delivered_month, number_of_agency_master_files_delivered_month, number_of_agency_units_archived_month, number_of_agency_master_files_archived_month
               sheet3_i = sheet3_i.next
            end
         end

         sheet3_i += 1
      end

      ####################################
      # Sheet 4 (By Agency Year-To-Date)
      ####################################
      sheet4 = book.create_worksheet
      sheet4.name = 'By Agency (Year-To-Date)'

      agency_year_heading_text = "Total Orders By Agency - Year-To-Date (#{query_year})"
      agency_year_heading_row = sheet4.row(0)
      for i in 0..11 do
         agency_year_heading_row.set_format(i, heading_format)
      end
      agency_year_heading_row[0] = agency_year_heading_text

      sheet4_i = 2 #Start on row 2

      # Sheet4 Sub-headings
      sheet4.row(1).replace [ 'Agencies', 'Orders in Process', 'Orders Submitted', 'Orders Deferred', 'Orders Approved', 'Orders Canceled', 'Orders Archived', 'Orders Delivered', 'Units Delivered', 'Master Files Delivered', 'Units Archived', 'Master Files Archived' ]
      for i in 0..11 do
         sheet4.row(1).set_format(i, sub_heading_format)
      end

      Agency.order(:name).each do |agency|
         number_of_agency_orders_currently_in_process = agency.orders.in_process.count
         number_of_agency_orders_submitted_year = agency.orders.where("date_request_submitted between '#{query_year}-01-01' and '#{query_year}-12-31'").count
         number_of_agency_orders_deferred_year = agency.orders.where("date_deferred between '#{query_year}-01-01' and '#{query_year}-12-31'").count
         number_of_agency_orders_approved_year = agency.orders.where("date_order_approved between '#{query_year}-01-01' and '#{query_year}-12-31'").count
         number_of_agency_orders_canceled_year = agency.orders.where("date_canceled between '#{query_year}-01-01' and '#{query_year}-12-31'").count
         number_of_agency_orders_archived_year = agency.orders.where("date_archiving_complete between '#{query_year}-01-01' and '#{query_year}-12-31'").count
         number_of_agency_orders_delivered_year = agency.orders.where("date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'").count
         number_of_agency_units_delivered_year = agency.units.joins(:order).where("`orders`.date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'").count
         number_of_agency_units_archived_year = agency.units.where("date_archived between '#{query_year}-01-01' and '#{query_year}-12-31'").count
         number_of_agency_master_files_archived_year = agency.master_files.where("`master_files`.date_archived between '#{query_year}-01-01' and '#{query_year}-12-31'").count
         number_of_agency_master_files_delivered_year = agency.master_files.joins(:order).where("`orders`.date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'").count

         if number_of_agency_orders_currently_in_process == 0 and number_of_agency_orders_submitted_year == 0 and number_of_agency_orders_deferred_year == 0 and number_of_agency_orders_approved_year == 0 and number_of_agency_orders_canceled_year == 0 and number_of_agency_orders_archived_year == 0 and number_of_agency_orders_delivered_year == 0 and number_of_agency_units_delivered_year == 0 and number_of_agency_units_archived_year == 0 and number_of_agency_master_files_archived_year == 0 and number_of_agency_master_files_delivered_year == 0
         else
            sheet4.row(sheet4_i).push agency.name, number_of_agency_orders_currently_in_process, number_of_agency_orders_submitted_year, number_of_agency_orders_deferred_year, number_of_agency_orders_approved_year, number_of_agency_orders_canceled_year, number_of_agency_orders_archived_year, number_of_agency_orders_delivered_year, number_of_agency_units_delivered_year, number_of_agency_master_files_delivered_year, number_of_agency_units_archived_year, number_of_agency_master_files_archived_year
            sheet4_i = sheet4_i.next
         end
      end

      ####################################
      # Sheet 5 (Current Orders)
      ####################################
      sheet5 = book.create_worksheet
      sheet5.name = 'Current Orders'

      sheet5.row(0).replace ['Status', "Total as of #{today.month}/#{today.day}/#{today.year}"]
      for i in 0..1 do
         sheet5.row(0).set_format(i, sub_heading_format)
      end

      sheet5.row(1).push 'Orders Currently in Process', Order.in_process.count
      sheet5.row(2).push 'Orders Currently Pending Approval', Order.awaiting_approval.count
      sheet5.row(3).push 'Orders Currently Deferred', Order.deferred.count

      # Let's do some formatting!
      # Some templates
      format = Spreadsheet::Format.new :horizontal_align => :center

      # Sheet 1
      sheet1.row(0).default_format = format
      sheet1.row(1).default_format = format
      sheet1.row(11).default_format = format

      # Save the entire workbook
      t = DateTime.now
      filename = "#{query_year}_Report_#{t.year}-#{t.month}-#{t.day}-#{t.hour}-#{t.min}-#{t.sec}"
      report_path = "#{PRODUCTION_MOUNT}/administrative/stats_reports/#{filename}.xls"
      logger.info("Writing stats report to: #{report_path}")
      book.write report_path
      on_success "Stats reported created."

   end
end
