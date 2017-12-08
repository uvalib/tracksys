class CreateStatsReport < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"StaffMember", :originator_id=>message[:user_id])
   end

   def do_workflow(message)
   end

   # def do_workflow(message)
   #    today = Date.today
   #    query_year = message[:year]
   #
   #    if query_year.to_s == today.year.to_s
   #       query_month = today.month
   #    else
   #       query_month = 12
   #    end
   #
   #    # Create workbook and specify formatting
   #    pkg = Axlsx::Package.new
   #    wb = pkg.workbook
   #    wb.styles do |s|
   #       wb_style = {}
   #       wb_style[:header] = s.add_style :bg_color => "255FA6", :fg_color => "FFFFFF", :b=>true, :sz=>16, alignment: {horizontal: :center}
   #       wb_style[:date] = s.add_style :sz=>16, alignment: {horizontal: :center}
   #       wb_style[:right] =  s.add_style  alignment: {horizontal: :right}
   #       wb_style[:subheader] =  s.add_style  :b=>true, alignment: {horizontal: :right}
   #
   #       wb.add_worksheet(:name => "By Category") do |sheet|
   #          self.create_category( sheet, wb_style, query_year )
   #       end
   #
   #       wb.add_worksheet(:name => "Orders & Units") do |sheet|
   #          self.create_orders_and_units(sheet, wb_style, query_year, query_month)
   #       end
   #
   #       wb.add_worksheet(:name => "By Agency (Monthly Data)") do |sheet|
   #          self.create_agency_monthly(sheet, wb_style, query_year)
   #       end
   #
   #       wb.add_worksheet(:name => "By Agency (Year-To-Date)") do |sheet|
   #          self.create_agency_yearly(sheet, wb_style, query_year)
   #       end
   #
   #       wb.add_worksheet(:name => "Current Orders") do |sheet|
   #          self.create_current_orders(sheet, wb_style, query_year)
   #       end
   #    end
   #
   #    # Save the entire workbook
   #    t = DateTime.now
   #    filename = "#{query_year}_Report_#{t.year}-#{t.month}-#{t.day}-#{t.hour}-#{t.min}-#{t.sec}"
   #    report_path = "#{Settings.production_mount}/administrative/stats_reports/#{filename}.xlsx"
   #    logger.info("Writing stats report to: #{report_path}")
   #    pkg.serialize(report_path)
   #    staff_member = StaffMember.find_by(id: message[:user_id] )
   #    if !staff_member.nil?
   #       logger.info "Sending email notification to #{staff_member.email}"
   #       ReportMailer.stats_report_complete(staff_member, report_path).deliver_now
   #    end
   #    on_success "Stats reported created."
   # end
   #
   # # Create current order worksheet
   # #
   # def create_current_orders(sheet, styles, query_year)
   #    sheet.add_row ["Current Orders"], :style => [ styles[:header] ]
   #    sheet.merge_cells("A1:B1")
   #    sheet.add_row ['Status', "Total as of #{Date.today.strftime('%Y/%m/%d')}"], :style => styles[:subheader]
   #    sheet.add_row ['Orders Currently in Process', Order.in_process.count], :style => styles[:right]
   #    sheet.add_row ['Orders Currently Pending Approval', Order.awaiting_approval.count], :style => styles[:right]
   #    sheet.add_row ['Orders Currently Deferred', Order.deferred.count], :style => styles[:right]
   # end
   #
   # # Create Yearly agency worksheet
   # #
   # def create_agency_yearly(sheet, styles, query_year)
   #    sheet.add_row ["Total Orders by Agency - Year-To-Date (#{query_year})"], :style => [ styles[:header] ]
   #    sheet.merge_cells("A1:L1")
   #    sheet.add_row [ 'Agencies', 'Orders in Process', 'Orders Submitted', 'Orders Deferred',
   #                    'Orders Approved', 'Orders Canceled', 'Orders Archived', 'Orders Delivered',
   #                    'Units Delivered', 'Master Files Delivered', 'Units Archived', 'Master Files Archived' ],
   #                    :style=> styles[:subheader]
   #    sheet.column_widths 22,18,16,16,16,16,16,16,16,20,16,20
   #
   #    Agency.order(:name).each do |agency|
   #       r = [agency.name]
   #       r << agency.orders.in_process.count
   #       r << agency.orders.where("date_request_submitted between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #       r << agency.orders.where("date_deferred between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #       r << agency.orders.where("date_order_approved between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #       r << agency.orders.where("date_canceled between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #       r << agency.orders.where("date_archiving_complete between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #       r << agency.orders.where("date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #       r << agency.units.joins(:order).where("`orders`.date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #       r << agency.master_files.joins(:order).where("`orders`.date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #       r << agency.units.where("date_archived between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #       r << agency.master_files.where("`master_files`.date_archived between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #       sum = 0
   #       r.each { |v| sum+=v if v.is_a? Integer }
   #
   #       if sum > 0
   #          sheet.add_row r, :style=> styles[:right]
   #       end
   #    end
   # end
   #
   # # Create monthly angency worksheet
   # #
   # def create_agency_monthly(sheet, styles, query_year)
   #    sheet.add_row ["Agency Orders by Month"], :style => [ styles[:header] ]
   #    sheet.merge_cells("A1:K1")
   #
   #    for i in 1..12 do
   #       header_added = false
   #       data_added = false
   #       Agency.order(:name).each do |agency|
   #          r = [ agency.name ]
   #          r <<  agency.orders.where("date_request_submitted between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #          r <<  agency.orders.where("date_deferred between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #          r <<  agency.orders.where("date_order_approved between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #          r <<  agency.orders.where("date_canceled between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #          r <<  agency.orders.where("date_archiving_complete between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #          r <<  agency.orders.where("date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #          r <<  agency.units.joins(:order).where("orders.date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #          r <<  agency.master_files.joins(:order).where("orders.date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #          r <<  agency.units.where("date_archived between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #          r <<  agency.master_files.where("master_files.date_archived between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #          sum = 0
   #          r.each { |v| sum+=v if v.is_a? Integer }
   #
   #          if sum > 0
   #             if header_added == false
   #                header_added = true
   #                month_text = "#{i}/#{query_year}"
   #                sr = sheet.add_row [month_text], :style => styles[:date]
   #                sheet.merge_cells("A#{sr.row_index+1}:K#{sr.row_index+1}")
   #
   #                sheet.add_row [ 'Agencies', 'Orders Submitted', 'Orders Deferred', 'Orders Approved', 'Orders Canceled',
   #                                'Orders Archived', 'Orders Delivered', 'Units Delivered', 'Master Files Delivered',
   #                                'Units Archived', 'Master Files Archived' ], :style => styles[:subheader]
   #                sheet.column_widths 20,16,16,16,16,16,16,16,20,16,20
   #             end
   #             sheet.add_row r, :style => styles[:right]
   #             data_added = true
   #          end
   #       end
   #
   #       if data_added == true
   #          sr = sheet.add_row []
   #          sheet.merge_cells("A#{sr.row_index+1}:K#{sr.row_index+1}")
   #       end
   #    end
   # end
   #
   # # Create Categories worksheet
   # #
   # def create_category( sheet, styles, query_year )
   #    sheet.add_row ["Orders Submitted #{query_year}"], :style => styles[:header]
   #    sheet.merge_cells("A1:R1")
   #    sheet.add_row [ 'Category', 'January', 'February', 'March', 'April', 'May', 'June', 'July',
   #                    'August', 'September', 'October', 'November', 'December', '1st Quarter',
   #                    '2nd Quarter', '3rd Quarter', '4th Quarter', 'Year-To-Date'],
   #                    :style => styles[:subheader]
   #    sheet.column_widths 20,10,10,10,10,10,10,10,10,10,10,10,10,12,12,12,12,12
   #    AcademicStatus.order(:name).each do |status|
   #       r = [status.name]
   #       # monthly orders submitted
   #       for i in 1..12 do
   #          r << status.orders.where("date_request_submitted between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #       end
   #       # quarterly orders submitted
   #       r << status.orders.where("date_request_submitted between '#{query_year}-01-01' and '#{query_year}-03-31'").count
   #       r << status.orders.where("date_request_submitted between '#{query_year}-04-01' and '#{query_year}-06-30'").count
   #       r << status.orders.where("date_request_submitted between '#{query_year}-07-01' and '#{query_year}-09-30'").count
   #       r << status.orders.where("date_request_submitted between '#{query_year}-10-01' and '#{query_year}-12-31'").count
   #       r << status.orders.where("date_request_submitted between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #       sheet.add_row r, :style => styles[:right]
   #    end
   #
   #    r = ["Total"]
   #    for i in 1..12 do
   #       r << Order.where("date_request_submitted between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #    end
   #    r << Order.where("date_request_submitted between '#{query_year}-01-01' and '#{query_year}-03-31'").count
   #    r << Order.where("date_request_submitted between '#{query_year}-04-01' and '#{query_year}-06-30'").count
   #    r << Order.where("date_request_submitted between '#{query_year}-07-01' and '#{query_year}-09-30'").count
   #    r << Order.where("date_request_submitted between '#{query_year}-10-01' and '#{query_year}-12-31'").count
   #    r << Order.where("date_request_submitted between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #    sheet.add_row r, :style => styles[:right]
   #
   #    # Part II - Orders Delivered
   #    sheet.add_row []
   #    sheet.add_row ["Orders Delivered #{query_year}"], :style => styles[:header]
   #    sheet.merge_cells("A11:R11")
   #
   #    sheet.add_row [ 'Category', 'January', 'February', 'March', 'April', 'May',
   #                    'June', 'July', 'August', 'September', 'October', 'November',
   #                    'December', '1st Quarter', '2nd Quarter', '3rd Quarter',
   #                    '4th Quarter', 'Year-To-Date'], :style => styles[:subheader]
   #    sheet.column_widths 20,10,10,10,10,10,10,10,10,10,10,10,10,12,12,12,12,12
   #
   #    # Delivered Orders broken down by Academic Status
   #    AcademicStatus.order(:name).each do |status|
   #       r = [status.name]
   #       # monthly orders submitted
   #       for i in 1..12 do
   #          r << status.orders.where("date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #       end
   #       # quarterly orders submitted
   #       r << status.orders.where("date_customer_notified between '#{query_year}-01-01' and '#{query_year}-03-31'").count
   #       r << status.orders.where("date_customer_notified between '#{query_year}-04-01' and '#{query_year}-06-30'").count
   #       r << status.orders.where("date_customer_notified between '#{query_year}-07-01' and '#{query_year}-09-30'").count
   #       r << status.orders.where("date_customer_notified between '#{query_year}-10-01' and '#{query_year}-12-31'").count
   #       r << status.orders.where("date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #       sheet.add_row r, :style => styles[:right]
   #    end
   #
   #    # Totalling orders submitted
   #    r =  ["Total"]
   #    for i in 1..12 do
   #       r << Order.where("date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #    end
   #    r << Order.where("date_customer_notified between '#{query_year}-01-01' and '#{query_year}-03-31'").count
   #    r << Order.where("date_customer_notified between '#{query_year}-04-01' and '#{query_year}-06-30'").count
   #    r << Order.where("date_customer_notified between '#{query_year}-07-01' and '#{query_year}-09-30'").count
   #    r << Order.where("date_customer_notified between '#{query_year}-10-01' and '#{query_year}-12-31'").count
   #    r << Order.where("date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #    sheet.add_row r, :style => styles[:right]
   # end
   #
   # # Create Orders and Units workbook sheet
   # #
   # def create_orders_and_units( sheet, styles, query_year, query_month )
   #    sheet.add_row ["Orders and Units Data - #{query_year}"], :style => [ styles[:header] ]
   #    sheet.merge_cells("A1:O1")
   #    sheet.add_row [ 'Statistic', 'January', 'February', 'March', 'April', 'May',
   #                    'June', 'July', 'August', 'September', 'October', 'November',
   #                    'December', 'Year-To-Date', 'Average per month'],
   #                    :style => styles[:subheader]
   #    sheet.column_widths 28,10,10,10,10,10,10,10,10,10,10,10,10,18,18
   #
   #    # define table with 9 arrays, one for each row in the work book. Start each row with a name.
   #    # the remaining data will be filled in below...
   #    r = [ ['Orders Submitted'], ['Orders Delivered'], ['Orders Approved'],
   #          ['Orders Deferred'], ['Orders Canceled'], ['Units Archived'],
   #          ['Master Files Archived'], ['Size of Master Files Archived (GB)'], ['Units Delivered to DL'],
   #          ['Master Files Delivered to DL'] ]
   #
   #    # Append monthly stats to each row in the table structure defined above
   #    for i in 1..12 do
   #       r[0] << Order.where("date_request_submitted between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #       r[1] << Order.where("date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #       r[2] << Order.where("date_order_approved between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #       r[3] << Order.where("date_deferred between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #       r[4] << Order.where("date_canceled between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #       r[5] << Unit.where("date_archived between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #       r[6] << MasterFile.where("master_files.date_archived between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #       arch_size = MasterFile.where("master_files.date_archived between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").map(&:filesize).inject(:+)
   #       if !arch_size.nil?
   #          r[7] << ( arch_size / 1024000000 )
   #       else
   #          r[7] << 0
   #       end
   #       r[8] << Unit.where("date_dl_deliverables_ready between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #       r[9] << MasterFile.where("date_dl_ingest between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").count
   #    end
   #
   #    # Year to Date Stats
   #    r[0] << Order.where("date_request_submitted between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #    r[1] << Order.where("date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #    r[2] << Order.where("date_order_approved between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #    r[3] << Order.where("date_deferred between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #    r[4] << Order.where("date_canceled between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #    r[5] << Unit.where("date_archived between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #    r[6] << MasterFile.where("`master_files`.date_archived between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #    arch_size = MasterFile.where("`master_files`.date_archived between '#{query_year}-01-01' and '#{query_year}-12-31'").map(&:filesize).inject(:+)
   #    if !arch_size.nil?
   #       r[7] << ( arch_size / 1024000000 )
   #    else
   #       r[7] << 0
   #    end
   #    r[8] << Unit.where("date_dl_deliverables_ready between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #    r[9] << MasterFile.where("date_dl_ingest between '#{query_year}-01-01' and '#{query_year}-12-31'").count
   #
   #    # AVG Stats
   #    r[0] << r[0].last.to_i / query_month
   #    r[1] << r[1].last.to_i / query_month
   #    r[2] << r[2].last.to_i / query_month
   #    r[3] << r[3].last.to_i / query_month
   #    r[4] << r[4].last.to_i / query_month
   #    r[5] << r[5].last.to_i / query_month
   #    r[6] << r[6].last.to_i / query_month
   #    r[7] << r[7].last.to_i / query_month
   #    r[8] << r[8].last.to_i / query_month
   #    r[9] << r[9].last.to_i / query_month
   #
   #    # add all rows to the sheet
   #    r.each do |chart_row|
   #       sheet.add_row chart_row, :style => styles[:right]
   #    end
   # end
end
