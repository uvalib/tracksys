class CreateStatsReportProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  require 'spreadsheet'  
  subscribes_to :create_stats_report, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)  
    logger.debug "CreateStastsReportProcessor received: " + message
 
    hash = ActiveSupport::JSON.decode(message).symbolize_keys
    # TODO: Figure out how to message this processor
    # @messagable_id = hash[:master_file_id]
    # @messagable_type = "MasterFile"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)

    today = Date.today
    query_year = hash[:year]

    if query_year.to_s == today.year.to_s
      query_month = today.month
    else
      query_month = 12
    end

    logger.debug "hash[:year] is #{hash[:year]}"
    logger.debug "query_year is #{query_year}"
    logger.debug "today.year is #{today.year}"

    logger.debug "query_month is: #{query_month}"

    # Create and name the three worksheets   
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet
    sheet1.name = 'By Category'
    sheet2 = book.create_worksheet
    sheet2.name = 'Orders & Units'
    sheet3 = book.create_worksheet
    sheet3.name = 'By Agency (Monthly Data)'
    sheet4 = book.create_worksheet
    sheet4.name = 'By Agency (Year-To-Date)'
    sheet5 = book.create_worksheet
    sheet5.name = 'Current Orders'

    ####################################
    # Format Templates
    ####################################
    heading_format = Spreadsheet::Format.new(:weight => :bold, :size => 16, :align => :merge) 
    sub_heading_format = Spreadsheet::Format.new(:italic => 1)

    ####################################
    # Sheet1 Headings
    ####################################

    # 1.  Orders Submitted heading on sheet1
    orders_submitted_heading_text = "Orders Submitted #{query_year}"
    orders_submitted_heading_row = sheet1.row(0)
    for i in 1..17 do
      orders_submitted_heading_row.set_format(i, heading_format)
    end
    orders_submitted_heading_row[1] = orders_submitted_heading_text

    # 2. Orders Delivered heading on sheet1
    orders_delivered_heading_text = "Orders Delivered #{query_year}"
    orders_delivered_heading_row = sheet1.row(10)

    for i in 1..17 do
      orders_delivered_heading_row.set_format(i, heading_format)
    end  
    orders_delivered_heading_row[1] = orders_delivered_heading_text

    # Sheet1 Sub-headings
    sheet1.row(1).replace [ 'Category', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', '1st Quarter', '2nd Quarter', '3rd Quarter', '4th Quarter', 'Year-To-Date']
    sheet1.row(11).replace [ 'Category', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', '1st Quarter', '2nd Quarter', '3rd Quarter', '4th Quarter', 'Year-To-Date']

    # Format sheet1 sub-headings
    for i in 0..17 do
      sheet1.row(1).set_format(i, sub_heading_format)
      sheet1.row(11).set_format(i, sub_heading_format)
    end

    ####################################
    # Sheet2 Headings
    ####################################
    orders_and_units_heading_text = "Orders and Units Data - #{query_year}"
    orders_and_units_heading_row = sheet2.row(0)
    for i in 1..13 do
      orders_and_units_heading_row.set_format(i, heading_format)
    end
    orders_and_units_heading_row[1] = orders_and_units_heading_text

    # Sheet2 Sub-headings
    sheet2.row(1).replace [ 'Statistic', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', 'Year-To-Date', 'Average per month']

    for i in 0..15 do
      sheet2.row(1).set_format(i, sub_heading_format)
    end

    ####################################
    # Sheet3 Headings
    ####################################

    agency_month_heading_text = "Agency Orders By Month"
    agency_month_heading_row = sheet3.row(0)

    for j in 0..10 do
      agency_month_heading_row.set_format(j, heading_format)
    end

    agency_month_heading_row[0] = agency_month_heading_text

    # Due to the variable number of agencies that will be included in each month, these heading rows will be placed through the sheet and not
    # at static rows.  Therefore, I've moved the code for both the top and sub-headings to the code which populates the real data.

    ####################################
    # Sheet4 Headings
    ####################################

    agency_year_heading_text = "Total Orders By Agency - Year-To-Date (#{query_year})"
    agency_year_heading_row = sheet4.row(0)
    for i in 0..11 do
      agency_year_heading_row.set_format(i, heading_format)
    end
    agency_year_heading_row[0] = agency_year_heading_text

    ####################################
    # sheet5 Headings
    ####################################
    # sheet5 Sub-headings
    sheet5.row(0).replace ['Status', "Total as of #{today.month}/#{today.day}/#{today.year}"]

    for i in 0..1 do
      sheet5.row(0).set_format(i, sub_heading_format)
    end 

    ######################################
    # Gather stats for first worksheet
    ######################################
    # Part I - Orders Submitted
    # Write categories to sheet

    sheet1.row(2).push 'Faculty' 
    sheet1.row(3).push 'Staff'
    sheet1.row(4).push 'Graduate Student'
    sheet1.row(5).push 'Undergraduate Student'
    sheet1.row(6).push 'Non-UVA'
    sheet1.row(7).push 'DS4F'
    sheet1.row(8).push 'Total'

    sheet1.row(12).push 'Faculty' 
    sheet1.row(13).push 'Staff'
    sheet1.row(14).push 'Graduate Student'
    sheet1.row(15).push 'Undergraduate Student'
    sheet1.row(16).push 'Non-UVA'
    sheet1.row(17).push 'DS4F'
    sheet1.row(18).push 'Total'
   
    for i in 1..12 do
      all_orders_submitted_month = Order.find(:all, :conditions => "date_request_submitted between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'")
      number_of_orders_submitted_month = all_orders_submitted_month.length    

      faculty_orders_submitted_month = 0
      staff_orders_submitted_month = 0
      graduate_student_orders_submitted_month = 0
      undergraduate_student_orders_submitted_month = 0
      external_orders_submitted_month = 0
      ds4f_orders_submitted_month = 0    

      all_orders_submitted_month.each {|order|
        status = order.customer.uva_status.name.to_s
        if order.agency
          agency = order.agency.name
        else
          agency = ''
        end

        if status == 'Faculty'
          faculty_orders_submitted_month = faculty_orders_submitted_month.next
        elsif status == 'Non-UVA'
          external_orders_submitted_month = external_orders_submitted_month.next
        elsif status == 'Staff'
          staff_orders_submitted_month = staff_orders_submitted_month.next
        elsif status == 'Undergraduate Student'
          undergraduate_student_orders_submitted_month = undergraduate_student_orders_submitted_month.next
        elsif status == 'Graduate Student'
          graduate_student_orders_submitted_month = graduate_student_orders_submitted_month.next
        end

        if agency == 'DS4F'
          ds4f_orders_submitted_month = ds4f_orders_submitted_month.next
        end
      }

      # Write data for sheet1
      sheet1.row(2).push faculty_orders_submitted_month
      sheet1.row(3).push staff_orders_submitted_month
      sheet1.row(4).push graduate_student_orders_submitted_month
      sheet1.row(5).push undergraduate_student_orders_submitted_month
      sheet1.row(6).push external_orders_submitted_month
      sheet1.row(7).push ds4f_orders_submitted_month 
      sheet1.row(8).push number_of_orders_submitted_month
    end    
    
    # 3. Orders submitted for 1st quarter of query_year
    all_orders_submitted_first_quarter = Order.find(:all, :conditions => "date_request_submitted between '#{query_year}-01-01' and '#{query_year}-03-31'")
    number_of_orders_submitted_first_quarter = all_orders_submitted_first_quarter.length

    faculty_orders_submitted_first_quarter = 0
    graduate_student_orders_submitted_first_quarter = 0
    undergraduate_student_orders_submitted_first_quarter = 0
    external_orders_submitted_first_quarter = 0
    ds4f_orders_submitted_first_quarter = 0    
    staff_orders_submitted_first_quarter = 0

    all_orders_submitted_first_quarter.each {|order|
      status = order.customer.uva_status.name.to_s
      if order.agency
        agency = order.agency.name
      else
        agency = ''
      end

      if status == 'Faculty'
        faculty_orders_submitted_first_quarter = faculty_orders_submitted_first_quarter.next
      elsif status == 'Non-UVA'
        external_orders_submitted_first_quarter = external_orders_submitted_first_quarter.next
      elsif status == 'Staff'
        staff_orders_submitted_first_quarter = staff_orders_submitted_first_quarter.next
      elsif status == 'Undergraduate Student'
        undergraduate_student_orders_submitted_first_quarter = undergraduate_student_orders_submitted_first_quarter.next
      elsif status == 'Graduate Student'
        graduate_student_orders_submitted_first_quarter = graduate_student_orders_submitted_first_quarter.next
      end

      if agency == 'DS4F'
        ds4f_orders_submitted_first_quarter = ds4f_orders_submitted_first_quarter.next
      end
    }

    sheet1.row(2).push faculty_orders_submitted_first_quarter
    sheet1.row(3).push staff_orders_submitted_first_quarter
    sheet1.row(4).push graduate_student_orders_submitted_first_quarter
    sheet1.row(5).push undergraduate_student_orders_submitted_first_quarter
    sheet1.row(6).push external_orders_submitted_first_quarter
    sheet1.row(7).push ds4f_orders_submitted_first_quarter 
    sheet1.row(8).push number_of_orders_submitted_first_quarter

    # 4. Orders submitted submitted for 2nd quarter of query_year
    all_orders_submitted_second_quarter = Order.find(:all, :conditions => "date_request_submitted between '#{query_year}-04-01' and '#{query_year}-06-30'")
    number_of_orders_submitted_second_quarter = all_orders_submitted_second_quarter.length

    faculty_orders_submitted_second_quarter = 0
    staff_orders_submitted_second_quarter = 0
    graduate_student_orders_submitted_second_quarter = 0
    undergraduate_student_orders_submitted_second_quarter = 0
    external_orders_submitted_second_quarter = 0
    ds4f_orders_submitted_second_quarter = 0    

    all_orders_submitted_second_quarter.each {|order|
      status = order.customer.uva_status.name.to_s
      if order.agency
        agency = order.agency.name
      else
        agency = ''
      end

      if status == 'Faculty'
        faculty_orders_submitted_second_quarter = faculty_orders_submitted_second_quarter.next
      elsif status == 'Non-UVA'
        external_orders_submitted_second_quarter = external_orders_submitted_second_quarter.next
      elsif status == 'Staff'
        staff_orders_submitted_second_quarter = staff_orders_submitted_second_quarter.next
      elsif status == 'Undergraduate Student'
        undergraduate_student_orders_submitted_second_quarter = undergraduate_student_orders_submitted_second_quarter.next
      elsif status == 'Graduate Student'
        graduate_student_orders_submitted_second_quarter = graduate_student_orders_submitted_second_quarter.next
      end

      if agency == 'DS4F'
        ds4f_orders_submitted_second_quarter = ds4f_orders_submitted_second_quarter.next
      end
    }

    sheet1.row(2).push faculty_orders_submitted_second_quarter
    sheet1.row(3).push staff_orders_submitted_second_quarter
    sheet1.row(4).push graduate_student_orders_submitted_second_quarter
    sheet1.row(5).push undergraduate_student_orders_submitted_second_quarter
    sheet1.row(6).push external_orders_submitted_second_quarter
    sheet1.row(7).push ds4f_orders_submitted_second_quarter 
    sheet1.row(8).push number_of_orders_submitted_second_quarter
    
    # 5. Orders submitted for 3rd quarter of query_year
    all_orders_submitted_third_quarter = Order.find(:all, :conditions => "date_request_submitted between '#{query_year}-07-01' and '#{query_year}-09-30'")
    number_of_orders_submitted_third_quarter = all_orders_submitted_third_quarter.length

    faculty_orders_submitted_third_quarter = 0
    staff_orders_submitted_third_quarter = 0
    graduate_student_orders_submitted_third_quarter = 0
    undergraduate_student_orders_submitted_third_quarter = 0
    external_orders_submitted_third_quarter = 0
    ds4f_orders_submitted_third_quarter = 0    

    all_orders_submitted_third_quarter.each {|order|
      status = order.customer.uva_status.name.to_s
      if order.agency
        agency = order.agency.name
      else
        agency = ''
      end

      if status == 'Faculty'
        faculty_orders_submitted_third_quarter = faculty_orders_submitted_third_quarter.next
      elsif status == 'Non-UVA'
        external_orders_submitted_third_quarter = external_orders_submitted_third_quarter.next
      elsif status == 'Staff'
        staff_orders_submitted_third_quarter = staff_orders_submitted_third_quarter.next
      elsif status == 'Undergraduate Student'
        undergraduate_student_orders_submitted_third_quarter = undergraduate_student_orders_submitted_third_quarter.next
      elsif status == 'Graduate Student'
        graduate_student_orders_submitted_third_quarter = graduate_student_orders_submitted_third_quarter.next
      end

      if agency == 'DS4F'
        ds4f_orders_submitted_third_quarter = ds4f_orders_submitted_third_quarter.next
      end
    }

    sheet1.row(2).push faculty_orders_submitted_third_quarter
    sheet1.row(3).push staff_orders_submitted_third_quarter
    sheet1.row(4).push graduate_student_orders_submitted_third_quarter
    sheet1.row(5).push undergraduate_student_orders_submitted_third_quarter
    sheet1.row(6).push external_orders_submitted_third_quarter
    sheet1.row(7).push ds4f_orders_submitted_third_quarter 
    sheet1.row(8).push number_of_orders_submitted_third_quarter
    
    # 6.  Orders submitted for 4th quarter of query_year
    all_orders_submitted_fourth_quarter = Order.find(:all, :conditions => "date_request_submitted between '#{query_year}-10-01' and '#{query_year}-12-31'")
    number_of_orders_submitted_fourth_quarter = all_orders_submitted_fourth_quarter.length

    faculty_orders_submitted_fourth_quarter = 0
    staff_orders_submitted_fourth_quarter = 0
    graduate_student_orders_submitted_fourth_quarter = 0
    undergraduate_student_orders_submitted_fourth_quarter = 0
    external_orders_submitted_fourth_quarter = 0
    ds4f_orders_submitted_fourth_quarter = 0    

    all_orders_submitted_fourth_quarter.each {|order|
      status = order.customer.uva_status.name.to_s
      if order.agency
        agency = order.agency.name
      else
        agency = ''
      end

      if status == 'Faculty'
        faculty_orders_submitted_fourth_quarter = faculty_orders_submitted_fourth_quarter.next
      elsif status == 'Non-UVA'
        external_orders_submitted_fourth_quarter = external_orders_submitted_fourth_quarter.next
      elsif status == 'Staff'
        staff_orders_submitted_fourth_quarter = staff_orders_submitted_fourth_quarter.next
      elsif status == 'Undergraduate Student'
        undergraduate_student_orders_submitted_fourth_quarter = undergraduate_student_orders_submitted_fourth_quarter.next
      elsif status == 'Graduate Student'
        graduate_student_orders_submitted_fourth_quarter = graduate_student_orders_submitted_fourth_quarter.next
      end

      if agency == 'DS4F'
        ds4f_orders_submitted_fourth_quarter = ds4f_orders_submitted_fourth_quarter.next
      end
    }

    sheet1.row(2).push faculty_orders_submitted_fourth_quarter
    sheet1.row(3).push staff_orders_submitted_fourth_quarter
    sheet1.row(4).push graduate_student_orders_submitted_fourth_quarter
    sheet1.row(5).push undergraduate_student_orders_submitted_fourth_quarter
    sheet1.row(6).push external_orders_submitted_fourth_quarter
    sheet1.row(7).push ds4f_orders_submitted_fourth_quarter 
    sheet1.row(8).push number_of_orders_submitted_fourth_quarter

    # 2. Orders submitted for year-to-date
    all_orders_submitted_year_to_date = Order.find(:all, :conditions => "date_request_submitted between '#{query_year}-01-01' and '#{query_year}-12-31'")
    number_of_orders_submitted_year_to_date = all_orders_submitted_year_to_date.length    

    faculty_orders_submitted_year_to_date = 0
    staff_orders_submitted_year_to_date = 0
    graduate_student_orders_submitted_year_to_date = 0
    undergraduate_student_orders_submitted_year_to_date = 0
    external_orders_submitted_year_to_date = 0
    ds4f_orders_submitted_year_to_date = 0    

    all_orders_submitted_year_to_date.each {|order|
      status = order.customer.uva_status.name.to_s
      if order.agency
        agency = order.agency.name
      else
        agency = ''
      end

      if status == 'Faculty'
        faculty_orders_submitted_year_to_date = faculty_orders_submitted_year_to_date.next
      elsif status == 'Non-UVA'
        external_orders_submitted_year_to_date = external_orders_submitted_year_to_date.next
      elsif status == 'Staff'
        staff_orders_submitted_year_to_date = staff_orders_submitted_year_to_date.next
      elsif status == 'Undergraduate Student'
        undergraduate_student_orders_submitted_year_to_date = undergraduate_student_orders_submitted_year_to_date.next
      elsif status == 'Graduate Student'
        graduate_student_orders_submitted_year_to_date = graduate_student_orders_submitted_year_to_date.next
      end

      if agency == 'DS4F'
        ds4f_orders_submitted_year_to_date = ds4f_orders_submitted_year_to_date.next
      end
    }

    sheet1.row(2).push faculty_orders_submitted_year_to_date
    sheet1.row(3).push staff_orders_submitted_year_to_date
    sheet1.row(4).push graduate_student_orders_submitted_year_to_date
    sheet1.row(5).push undergraduate_student_orders_submitted_year_to_date
    sheet1.row(6).push external_orders_submitted_year_to_date
    sheet1.row(7).push ds4f_orders_submitted_year_to_date 
    sheet1.row(8).push number_of_orders_submitted_year_to_date

    ###########################
    # Orders Delivered
    ############################

    # Part II - Orders delivered
    # 1. Orders delivered for different months

    for i in 1..12 do
      all_orders_delivered_month = Order.find(:all, :conditions => "date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'")
      number_of_orders_delivered_month = all_orders_delivered_month.length    
    
      faculty_orders_delivered_month = 0
      staff_orders_delivered_month = 0
      graduate_student_orders_delivered_month = 0
      undergraduate_student_orders_delivered_month = 0
      external_orders_delivered_month = 0
      ds4f_orders_delivered_month = 0    

      all_orders_delivered_month.each {|order|
        status = order.customer.uva_status.name.to_s
        if order.agency
          agency = order.agency.name
        else
          agency = ''
        end

        if status == 'Faculty'
          faculty_orders_delivered_month = faculty_orders_delivered_month.next
        elsif status == 'Non-UVA'
          external_orders_delivered_month = external_orders_delivered_month.next
        elsif status == 'Staff'
          staff_orders_delivered_month = staff_orders_delivered_month.next
        elsif status == 'Undergraduate Student'
          undergraduate_student_orders_delivered_month = undergraduate_student_orders_delivered_month.next
        elsif status == 'Graduate Student'
          graduate_student_orders_delivered_month = graduate_student_orders_delivered_month.next
        end

        if agency == 'DS4F'
          ds4f_orders_delivered_month = ds4f_orders_delivered_month.next
        end
      }

      sheet1.row(12).push faculty_orders_delivered_month
      sheet1.row(13).push staff_orders_delivered_month
      sheet1.row(14).push graduate_student_orders_delivered_month
      sheet1.row(15).push undergraduate_student_orders_delivered_month
      sheet1.row(16).push external_orders_delivered_month
      sheet1.row(17).push ds4f_orders_delivered_month 
      sheet1.row(18).push number_of_orders_delivered_month
    end

    # 3. Orders delivered for 1st quarter of query_year
    all_orders_delivered_first_quarter = Order.find(:all, :conditions => "date_customer_notified between '#{query_year}-01-01' and '#{query_year}-03-31'")
    number_of_orders_delivered_first_quarter = all_orders_delivered_first_quarter.length

    faculty_orders_delivered_first_quarter = 0
    staff_orders_delivered_first_quarter = 0
    graduate_student_orders_delivered_first_quarter = 0
    undergraduate_student_orders_delivered_first_quarter = 0
    external_orders_delivered_first_quarter = 0
    ds4f_orders_delivered_first_quarter = 0    

    all_orders_delivered_first_quarter.each {|order|
      status = order.customer.uva_status.name.to_s
      if order.agency
        agency = order.agency.name
      else
        agency = ''
      end

      if status == 'Faculty'
        faculty_orders_delivered_first_quarter = faculty_orders_delivered_first_quarter.next
      elsif status == 'Non-UVA'
        external_orders_delivered_first_quarter = external_orders_delivered_first_quarter.next
      elsif status == 'Staff'
        staff_orders_delivered_first_quarter = staff_orders_delivered_first_quarter.next
      elsif status == 'Undergraduate Student'
        undergraduate_student_orders_delivered_first_quarter = undergraduate_student_orders_delivered_first_quarter.next
      elsif status == 'Graduate Student'
        graduate_student_orders_delivered_first_quarter = graduate_student_orders_delivered_first_quarter.next
      end

      if agency == 'DS4F'
        ds4f_orders_delivered_first_quarter = ds4f_orders_delivered_first_quarter.next
      end
    }

    sheet1.row(12).push faculty_orders_delivered_first_quarter
    sheet1.row(13).push staff_orders_delivered_first_quarter
    sheet1.row(14).push graduate_student_orders_delivered_first_quarter
    sheet1.row(15).push undergraduate_student_orders_delivered_first_quarter
    sheet1.row(16).push external_orders_delivered_first_quarter
    sheet1.row(17).push ds4f_orders_delivered_first_quarter 
    sheet1.row(18).push number_of_orders_delivered_first_quarter

    # 4. Orders delivered delivered for 2nd quarter of query_year
    all_orders_delivered_second_quarter = Order.find(:all, :conditions => "date_customer_notified between '#{query_year}-04-01' and '#{query_year}-06-30'")
    number_of_orders_delivered_second_quarter = all_orders_delivered_second_quarter.length

    faculty_orders_delivered_second_quarter = 0
    staff_orders_delivered_second_quarter = 0
    graduate_student_orders_delivered_second_quarter = 0
    undergraduate_student_orders_delivered_second_quarter = 0
    external_orders_delivered_second_quarter = 0
    ds4f_orders_delivered_second_quarter = 0    

    all_orders_delivered_second_quarter.each {|order|
      status = order.customer.uva_status.name.to_s
      if order.agency
        agency = order.agency.name
      else
        agency = ''
      end

      if status == 'Faculty'
        faculty_orders_delivered_second_quarter = faculty_orders_delivered_second_quarter.next
      elsif status == 'Non-UVA'
        external_orders_delivered_second_quarter = external_orders_delivered_second_quarter.next
      elsif status == 'Staff'
        staff_orders_delivered_second_quarter = staff_orders_delivered_second_quarter.next
      elsif status == 'Undergraduate Student'
        undergraduate_student_orders_delivered_second_quarter = undergraduate_student_orders_delivered_second_quarter.next
      elsif status == 'Graduate Student'
        graduate_student_orders_delivered_second_quarter = graduate_student_orders_delivered_second_quarter.next
      end

      if agency == 'DS4F'
        ds4f_orders_delivered_second_quarter = ds4f_orders_delivered_second_quarter.next
      end
    }

    sheet1.row(12).push faculty_orders_delivered_second_quarter
    sheet1.row(13).push staff_orders_delivered_second_quarter
    sheet1.row(14).push graduate_student_orders_delivered_second_quarter
    sheet1.row(15).push undergraduate_student_orders_delivered_second_quarter
    sheet1.row(16).push external_orders_delivered_second_quarter
    sheet1.row(17).push ds4f_orders_delivered_second_quarter 
    sheet1.row(18).push number_of_orders_delivered_second_quarter
    
    # 5. Orders delivered for 3rd quarter of query_year
    all_orders_delivered_third_quarter = Order.find(:all, :conditions => "date_customer_notified between '#{query_year}-07-01' and '#{query_year}-09-30'")
    number_of_orders_delivered_third_quarter = all_orders_delivered_third_quarter.length

    faculty_orders_delivered_third_quarter = 0
    staff_orders_delivered_third_quarter = 0
    graduate_student_orders_delivered_third_quarter = 0
    undergraduate_student_orders_delivered_third_quarter = 0
    external_orders_delivered_third_quarter = 0
    ds4f_orders_delivered_third_quarter = 0    

    all_orders_delivered_third_quarter.each {|order|
      status = order.customer.uva_status.name.to_s
      if order.agency
        agency = order.agency.name
      else
        agency = ''
      end

      if status == 'Faculty'
        faculty_orders_delivered_third_quarter = faculty_orders_delivered_third_quarter.next
      elsif status == 'Non-UVA'
        external_orders_delivered_third_quarter = external_orders_delivered_third_quarter.next
      elsif status == 'Staff'
        staff_orders_delivered_third_quarter = staff_orders_delivered_third_quarter.next
      elsif status == 'Undergraduate Student'
        undergraduate_student_orders_delivered_third_quarter = undergraduate_student_orders_delivered_third_quarter.next
      elsif status == 'Graduate Student'
        graduate_student_orders_delivered_third_quarter = graduate_student_orders_delivered_third_quarter.next
      end

      if agency == 'DS4F'
        ds4f_orders_delivered_third_quarter = ds4f_orders_delivered_third_quarter.next
      end
    }

    sheet1.row(12).push faculty_orders_delivered_third_quarter
    sheet1.row(13).push staff_orders_delivered_third_quarter
    sheet1.row(14).push graduate_student_orders_delivered_third_quarter
    sheet1.row(15).push undergraduate_student_orders_delivered_third_quarter
    sheet1.row(16).push external_orders_delivered_third_quarter
    sheet1.row(17).push ds4f_orders_delivered_third_quarter 
    sheet1.row(18).push number_of_orders_delivered_third_quarter
    
    # 6.  Orders delivered for 4th quarter of query_year
    all_orders_delivered_fourth_quarter = Order.find(:all, :conditions => "date_customer_notified between '#{query_year}-10-01' and '#{query_year}-12-31'")
    number_of_orders_delivered_fourth_quarter = all_orders_delivered_fourth_quarter.length

    faculty_orders_delivered_fourth_quarter = 0
    staff_orders_delivered_fourth_quarter = 0
    graduate_student_orders_delivered_fourth_quarter = 0
    undergraduate_student_orders_delivered_fourth_quarter = 0
    external_orders_delivered_fourth_quarter = 0
    ds4f_orders_delivered_fourth_quarter = 0    

    all_orders_delivered_fourth_quarter.each {|order|
      status = order.customer.uva_status.name.to_s
      if order.agency
        agency = order.agency.name
      else
        agency = ''
      end

      if status == 'Faculty'
        faculty_orders_delivered_fourth_quarter = faculty_orders_delivered_fourth_quarter.next
      elsif status == 'Non-UVA'
        external_orders_delivered_fourth_quarter = external_orders_delivered_fourth_quarter.next
      elsif status == 'Staff'
        staff_orders_delivered_fourth_quarter = staff_orders_delivered_fourth_quarter.next
      elsif status == 'Undergraduate Student'
        undergraduate_student_orders_delivered_fourth_quarter = undergraduate_student_orders_delivered_fourth_quarter.next
      elsif status == 'Graduate Student'
        graduate_student_orders_delivered_fourth_quarter = graduate_student_orders_delivered_fourth_quarter.next
      end

      if agency == 'DS4F'
        ds4f_orders_delivered_fourth_quarter = ds4f_orders_delivered_fourth_quarter.next
      end
    }

    sheet1.row(12).push faculty_orders_delivered_fourth_quarter
    sheet1.row(13).push staff_orders_delivered_fourth_quarter
    sheet1.row(14).push graduate_student_orders_delivered_fourth_quarter
    sheet1.row(15).push undergraduate_student_orders_delivered_fourth_quarter
    sheet1.row(16).push external_orders_delivered_fourth_quarter
    sheet1.row(17).push ds4f_orders_delivered_fourth_quarter 
    sheet1.row(18).push number_of_orders_delivered_fourth_quarter

    # 2. Orders delivered for year-to-date
    all_orders_delivered_year_to_date = Order.find(:all, :conditions => "date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31'")
    number_of_orders_delivered_year_to_date = all_orders_delivered_year_to_date.length    

    faculty_orders_delivered_year_to_date = 0
    staff_orders_delivered_year_to_date = 0
    graduate_student_orders_delivered_year_to_date = 0
    undergraduate_student_orders_delivered_year_to_date = 0
    external_orders_delivered_year_to_date = 0
    ds4f_orders_delivered_year_to_date = 0    

    all_orders_delivered_year_to_date.each {|order|
      status = order.customer.uva_status.name.to_s
      if order.agency
        agency = order.agency.name
      else
        agency = ''
      end

      if status == 'Faculty'
        faculty_orders_delivered_year_to_date = faculty_orders_delivered_year_to_date.next
      elsif status == 'Non-UVA'
        external_orders_delivered_year_to_date = external_orders_delivered_year_to_date.next
      elsif status == 'Staff'
        staff_orders_delivered_year_to_date = staff_orders_delivered_year_to_date.next
      elsif status == 'Undergraduate Student'
        undergraduate_student_orders_delivered_year_to_date = undergraduate_student_orders_delivered_year_to_date.next
      elsif status == 'Graduate Student'
        graduate_student_orders_delivered_year_to_date = graduate_student_orders_delivered_year_to_date.next
      end

      if agency == 'DS4F'
        ds4f_orders_delivered_year_to_date = ds4f_orders_delivered_year_to_date.next
      end
    }

    sheet1.row(12).push faculty_orders_delivered_year_to_date
    sheet1.row(13).push staff_orders_delivered_year_to_date
    sheet1.row(14).push graduate_student_orders_delivered_year_to_date
    sheet1.row(15).push undergraduate_student_orders_delivered_year_to_date
    sheet1.row(16).push external_orders_delivered_year_to_date
    sheet1.row(17).push ds4f_orders_delivered_year_to_date 
    sheet1.row(18).push number_of_orders_delivered_year_to_date

    ## Sheet 2
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
 
    # Total size of master files for the year is for all units, so the emtpy integer variable can be decleared up front
    size_of_master_files_archived_year_to_date = 0

    for i in 1..12 do
      # Total size of master files is for all units, so the emtpy integer variable can be decleared up front
      size_of_master_files_archived_month = 0
      
      # Orders Submitted 
      number_of_orders_submitted_month = Order.find(:all, :conditions => "date_request_submitted between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").length

      # Orders Delivered
      number_of_orders_delivered_month = Order.find(:all, :conditions => "date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").length

      # Orders Approved
      number_of_orders_approved_month = Order.find(:all, :conditions => "date_order_approved between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").length

      # Orders Deferred
      number_of_orders_deferred_month = Order.find(:all, :conditions => "date_deferred between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").length

      # Orders Canceled
      number_of_orders_canceled_month = Order.find(:all, :conditions => "date_canceled between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'").length

      # Units and Master Files Archived
      units_archived_month = Unit.find(:all, :conditions => "date_archived between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'")
      number_of_units_archived_month = units_archived_month.length
      number_of_master_files_archived_month = 0
      units_archived_month.each {|unit|
        number_of_master_files_archived_month = number_of_master_files_archived_month + unit.master_files.length
        unit.master_files.each {|mf|
           if not mf.filesize.nil?
             size_of_master_files_archived_month = size_of_master_files_archived_month + mf.filesize
             size_of_master_files_archived_year_to_date = size_of_master_files_archived_year_to_date + mf.filesize
           end
        }
      }

      # Units and Master Files Delivered to DL
      units_delivered_to_dl_month = Unit.find(:all, :conditions => "date_dl_deliverables_ready between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'")
      number_of_units_delivered_to_dl_month = units_delivered_to_dl_month.length

      number_of_master_files_delivered_to_dl_month = 0
  
      units_delivered_to_dl_month.each {|unit|
        number_of_master_files_delivered_to_dl_month = number_of_master_files_delivered_to_dl_month + unit.master_files.length  
      }

      # Begin writing data for sheet2
      sheet2.row(2).push number_of_orders_submitted_month
      sheet2.row(3).push number_of_orders_delivered_month
      sheet2.row(4).push number_of_orders_approved_month
      sheet2.row(5).push number_of_orders_deferred_month
      sheet2.row(6).push number_of_orders_canceled_month
      sheet2.row(7).push number_of_units_archived_month
      sheet2.row(8).push number_of_master_files_archived_month
      # convert the size from bytes to gigabytes
      sheet2.row(9).push size_of_master_files_archived_month / 1024000000
      sheet2.row(10).push number_of_units_delivered_to_dl_month
      sheet2.row(11).push number_of_master_files_delivered_to_dl_month
    end

    # Year to Date Stats
    number_of_orders_approved_year_to_date = Order.find(:all, :conditions => "date_order_approved between '#{query_year}-01-01' and '#{query_year}-12-31'").length
    number_of_orders_deferred_year_to_date = Order.find(:all, :conditions => "date_deferred between '#{query_year}-01-01' and '#{query_year}-12-31'").length
    number_of_orders_canceled_year_to_date = Order.find(:all, :conditions => "date_canceled between '#{query_year}-01-01' and '#{query_year}-12-31'").length
    units_archived_year_to_date = Unit.find(:all, :conditions => "date_archived between '#{query_year}-01-01' and '#{query_year}-12-31'")
    number_of_units_archived_year_to_date = units_archived_year_to_date.length

    number_of_master_files_archived_year_to_date = 0
    units_archived_year_to_date.each {|unit|
      number_of_master_files_archived_year_to_date = number_of_master_files_archived_year_to_date + unit.master_files.length
    }

    units_delivered_to_dl_year_to_date = Unit.find(:all, :conditions => "date_dl_deliverables_ready between '#{query_year}-01-01' and '#{query_year}-12-31'")
    number_of_units_delivered_to_dl_year_to_date = units_delivered_to_dl_year_to_date.length
    number_of_master_files_delivered_to_dl_year_to_date = 0
    units_delivered_to_dl_year_to_date.each {|unit|
      number_of_master_files_delivered_to_dl_year_to_date = number_of_master_files_delivered_to_dl_year_to_date + unit.master_files.length  
    }

    sheet2.row(2).push number_of_orders_submitted_year_to_date, number_of_orders_submitted_year_to_date / query_month
    sheet2.row(3).push number_of_orders_delivered_year_to_date, number_of_orders_delivered_year_to_date / query_month
    sheet2.row(4).push number_of_orders_approved_year_to_date, number_of_orders_approved_year_to_date / query_month
    sheet2.row(5).push number_of_orders_deferred_year_to_date, number_of_orders_deferred_year_to_date / query_month
    sheet2.row(6).push number_of_orders_canceled_year_to_date, number_of_orders_canceled_year_to_date / query_month
    sheet2.row(7).push number_of_units_archived_year_to_date, number_of_units_archived_year_to_date / query_month
    sheet2.row(8).push number_of_master_files_archived_year_to_date, number_of_master_files_archived_year_to_date / query_month
    sheet2.row(9).push size_of_master_files_archived_year_to_date / 1024000000, (size_of_master_files_archived_year_to_date / 1024000000) / query_month
    sheet2.row(10).push number_of_units_delivered_to_dl_year_to_date, number_of_units_delivered_to_dl_year_to_date / query_month
    sheet2.row(11).push number_of_master_files_delivered_to_dl_year_to_date, number_of_master_files_delivered_to_dl_year_to_date / query_month

    ####################################
    # Current Orders
    ####################################
    orders_currently_in_process = Order.find(:all, :conditions => "order_status = 'approved' and date_archiving_complete IS NULL")
    number_of_orders_currently_in_process = orders_currently_in_process.length

    orders_currently_pending_approval = Order.find(:all, :conditions => "order_status = 'requested'")
    number_of_orders_currently_pending_approval = orders_currently_pending_approval.length

    orders_currently_deferred = Order.find(:all, :conditions => "order_status = 'deferred'")
    number_of_orders_currently_deferred = orders_currently_deferred.length

    ####################################
    # Agency by Agency Data
    ####################################

    # Gather all the agency IDs and Names
    agency_info = Hash.new
    agencies = Agency.find(:all)

    # Create varialbe that will increment the row number for sheet3 and sheet4
    sheet3_i = 1
    sheet4_i = 2

    agencies.each {|agency|
      agency_info["#{agency.id}"] = "#{agency.name}"
    }

    # Sort hash by value rather than key
    agency_info = agency_info.sort {|a,b| a[1]<=>b[1]}

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
      sheet3_i = sheet3_i.next     

      units_archived_month = Unit.find(:all, :conditions => "date_archived between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31'")

      agency_info.each {|key, value|
        number_of_agency_orders_submitted_month = Order.find(:all, :conditions => "date_request_submitted between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31' and agency_id = '#{key}'").length
        number_of_agency_orders_deferred_month = Order.find(:all, :conditions => "date_deferred between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31' and agency_id = '#{key}'").length
        number_of_agency_orders_approved_month = Order.find(:all, :conditions => "date_order_approved between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31' and agency_id = '#{key}'").length
        number_of_agency_orders_canceled_month = Order.find(:all, :conditions => "date_canceled between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31' and agency_id = '#{key}'").length
        number_of_agency_orders_archived_month = Order.find(:all, :conditions => "date_archiving_complete between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31' and agency_id = '#{key}'").length
        number_of_agency_orders_delivered_month = Order.find(:all, :conditions => "date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31' and agency_id = '#{key}'").length

        number_of_agency_units_delivered_month = 0
        number_of_agency_units_archived_month = 0
        number_of_agency_master_files_archived_month = 0
        number_of_agency_master_files_delivered_month = 0

        agency_orders_delivered_month = Order.find(:all, :conditions => "date_customer_notified between '#{query_year}-#{i}-01' and '#{query_year}-#{i}-31' and agency_id = '#{key}'")
        agency_orders_delivered_month.each {|order|
          units = order.units
          number_of_agency_units_delivered_month = number_of_agency_units_delivered_month + units.length
          units.each {|unit|
            master_files = unit.master_files
            number_of_agency_master_files_delivered_month = number_of_agency_master_files_delivered_month + master_files.length   
          }	 
        }

        # In order to get the number of units and masterfiles that are archived from an order that is associated with an agency, we must
        # independently query the units table because relying upon other arrays (i.e. number_of_agency_order_archived_mont) remove the possibility
        # of getting units that are archived from orders that are not finished (i.e. delivered or archived in their entirety).

        units_archived_month.each {|unit|
          if unit.order.agency_id
            if unit.order.agency_id.to_s == key.to_s
              number_of_agency_units_archived_month = number_of_agency_units_archived_month.next
              if not unit.master_files.empty?
                master_files = unit.master_files
                number_of_agency_master_files_archived_month = number_of_agency_master_files_archived_month + master_files.length
              end
            end
          end
        }

        if number_of_agency_orders_submitted_month == 0 and number_of_agency_orders_deferred_month == 0 and number_of_agency_orders_approved_month == 0 and number_of_agency_orders_canceled_month == 0 and number_of_agency_orders_archived_month == 0 and number_of_agency_orders_delivered_month == 0 and number_of_agency_units_delivered_month == 0 and number_of_agency_units_archived_month == 0 and number_of_agency_master_files_archived_month == 0 and number_of_agency_master_files_delivered_month == 0
        else       
          sheet3.row(sheet3_i).push value, number_of_agency_orders_submitted_month, number_of_agency_orders_deferred_month, number_of_agency_orders_approved_month, number_of_agency_orders_canceled_month, number_of_agency_orders_archived_month, number_of_agency_orders_delivered_month, number_of_agency_units_delivered_month, number_of_agency_master_files_delivered_month, number_of_agency_units_archived_month, number_of_agency_master_files_archived_month
          sheet3_i = sheet3_i.next
        end
      }

      sheet3_i = sheet3_i.next
    end
  
    # Sheet4 Sub-headings
    sheet4.row(1).replace [ 'Agencies', 'Orders in Process', 'Orders Submitted', 'Orders Deferred', 'Orders Approved', 'Orders Canceled', 'Orders Archived', 'Orders Delivered', 'Units Delivered', 'Master Files Delivered', 'Units Archived', 'Master Files Archived' ]
    for i in 0..11 do
      sheet4.row(1).set_format(i, sub_heading_format)
    end 

    units_archived_year = Unit.find(:all, :conditions => "date_archived between '#{query_year}-01-01' and '#{query_year}-12-31'")

    agency_info.each {|key, value|
      number_of_agency_orders_currently_in_process = Order.find(:all, :conditions => "order_status = 'approved' and date_archiving_complete IS NULL and agency_id = '#{key}'").length
      number_of_agency_orders_submitted_year = Order.find(:all, :conditions => "date_request_submitted between '#{query_year}-01-01' and '#{query_year}-12-31' and agency_id = '#{key}'").length
      number_of_agency_orders_deferred_year = Order.find(:all, :conditions => "date_deferred between '#{query_year}-01-01' and '#{query_year}-12-31' and agency_id = '#{key}'").length
      number_of_agency_orders_approved_year = Order.find(:all, :conditions => "date_order_approved between '#{query_year}-01-01' and '#{query_year}-12-31' and agency_id = '#{key}'").length
      number_of_agency_orders_canceled_year = Order.find(:all, :conditions => "date_canceled between '#{query_year}-01-01' and '#{query_year}-12-31' and agency_id = '#{key}'").length
      number_of_agency_orders_archived_year = Order.find(:all, :conditions => "date_archiving_complete between '#{query_year}-01-01' and '#{query_year}-12-31' and agency_id = '#{key}'").length
      number_of_agency_orders_delivered_year = Order.find(:all, :conditions => "date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31' and agency_id = '#{key}'").length

      number_of_agency_units_delivered_year = 0
      number_of_agency_units_archived_year = 0
      number_of_agency_master_files_archived_year = 0
      number_of_agency_master_files_delivered_year = 0

      agency_orders_delivered_year = Order.find(:all, :conditions => "date_customer_notified between '#{query_year}-01-01' and '#{query_year}-12-31' and agency_id = '#{key}'")
      agency_orders_delivered_year.each {|order|
        units = order.units
        number_of_agency_units_delivered_year = number_of_agency_units_delivered_year + units.length
        units.each {|unit|
          master_files = unit.master_files
          number_of_agency_master_files_delivered_year = number_of_agency_master_files_delivered_year + master_files.length   
        }	 
      }

      # In order to get the number of units and masterfiles that are archived from an order that is associated with an agency, we must
      # independently query the units table because relying upon other arrays (i.e. number_of_agency_order_archived_mont) remove the possibility
      # of getting units that are archived from orders that are not finished (i.e. delivered or archived in their entirety).

      units_archived_year.each {|unit|
        if unit.order.agency_id
          if unit.order.agency_id.to_s == key.to_s
            number_of_agency_units_archived_year = number_of_agency_units_archived_year.next
            if not unit.master_files.empty?
              master_files = unit.master_files
              number_of_agency_master_files_archived_year = number_of_agency_master_files_archived_year + master_files.length
            end
          end
        end
      }

      if number_of_agency_orders_currently_in_process == 0 and number_of_agency_orders_submitted_year == 0 and number_of_agency_orders_deferred_year == 0 and number_of_agency_orders_approved_year == 0 and number_of_agency_orders_canceled_year == 0 and number_of_agency_orders_archived_year == 0 and number_of_agency_orders_delivered_year == 0 and number_of_agency_units_delivered_year == 0 and number_of_agency_units_archived_year == 0 and number_of_agency_master_files_archived_year == 0 and number_of_agency_master_files_delivered_year == 0
      else  
        sheet4.row(sheet4_i).push value, number_of_agency_orders_currently_in_process, number_of_agency_orders_submitted_year, number_of_agency_orders_deferred_year, number_of_agency_orders_approved_year, number_of_agency_orders_canceled_year, number_of_agency_orders_archived_year, number_of_agency_orders_delivered_year, number_of_agency_units_delivered_year, number_of_agency_master_files_delivered_year, number_of_agency_units_archived_year, number_of_agency_master_files_archived_year
        sheet4_i = sheet4_i.next
      end
    }

    ####################################
    # Write remaining data to spreadsheet
    ####################################

    # Write data for sheet5
    sheet5.row(1).push 'Orders Currently in Process', number_of_orders_currently_in_process

    sheet5.row(2).push 'Orders Currently Pending Approval', number_of_orders_currently_pending_approval

    sheet5.row(3).push 'Orders Currently Deferred', number_of_orders_currently_deferred

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
    book.write "/digiserv-production/administrative/stats_reports/#{filename}.xls"
    on_success "Stats reported created."

  end
end
