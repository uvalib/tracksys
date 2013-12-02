module BuildOrderPDF
  require 'prawn'
  def generate_notice
    @fee = self.fee_actual.to_i
    @customer = self.customer

    @units_in_pdf = Array.new
    self.units.each { |unit|        
      if unit.unit_status == 'approved'
        @units_in_pdf.push(unit)
      end
    }

    @pdf = Prawn::Document.new
    @pdf.font "Helvetica", :encoding => nil
    @pdf.image "#{Rails.root}/app/assets/images/lib_letterhead.jpg", :position => :center, :width => 500
    @pdf.text "Digital Curation Services,  University of Virginia Library", :align => :center
    @pdf.text "Post Office Box 400155, Charlottesville, Virginia 22904 U.S.A.", :align => :center
    @pdf.text "\n\n"
    @pdf.text "Order ID: #{self.id}", :align => :right, :font_size => 14
    @pdf.text "\n"
    @pdf.text "Dear #{@customer.first_name.capitalize} #{@customer.last_name.capitalize}, \n\n"  
    
    if @units_in_pdf.length > 1
      @pdf.text "On #{self.date_request_submitted.strftime("%B %d, %Y")} you placed an order with Digitization Services of the University of Virginia, Charlottesville, VA.  Your request comprised #{@units_in_pdf.length} items.  Below you will find a description of your digital order and how to cite the material for publication."
    else
      @pdf.text "On #{self.date_request_submitted.strftime("%B %d, %Y")} you placed an order with Digitization Services of the University of Virginia, Charlottesville, VA.  Your request comprised #{@units_in_pdf.length} item.  Below you will find a description of your digital order and how to cite the material for publication."
    end
    @pdf.text "\n"
    if not @fee.to_i.eql?(0)
      @pdf.text "Our records show that you accepted a fee of $#{@fee.to_i} for this order. This fee must be paid within 30 days.  Please write a check in the above amount made payable to <i>Digital Curation Services, UVa Library</i> and send it to the following address:", :inline_format => true
      @pdf.text "\n"
      @pdf.text "Digital Curation Services", :left => 100
      @pdf.text "University of Virginia Library", :left => 100
      @pdf.text "Post Office Box 400155", :left => 100
      @pdf.text "Charlottesville, Virginia 22904  U.S.A", :left => 100
    end

    @pdf.text "\n"
    @pdf.text "Sincerely,", :left => 350
    @pdf.text "\n"
    @pdf.text "Digitization Services Staff", :left => 350
    # End cover page

    # Begin first page of invoice
    @pdf.start_new_page

    @pdf.text "\n"
    @pdf.text "Digital Order Summary", :align => :center, :font_size => 16
    @pdf.text "\n"

    # Iterate through all the units belonging to this order
    @units_in_pdf.each { |unit|       
      # For pretty printing purposes, create pagebreak if there is less than 10 lines remaining on the current page.
      @pdf.start_new_page unless @pdf.cursor > 30

      # Add 1 to incrementation because index starts at 0
      item_number = @units_in_pdf.index(unit) + 1

      @pdf.text "Item ##{item_number}:", :font_size => 14
      @pdf.text "\n"

      # Begin work on Bibl record
      #
      # Output all present fields in Bibl record.  Almost all values in Bibl are optional, so tests are required.
      if unit.bibl_id?
        @pdf.text "Title: #{unit.bibl.title}", :left => 14 if unit.bibl.title?
        @pdf.text "Author: #{unit.bibl.creator_name}", :left => 14 if unit.bibl.creator_name?
        @pdf.text "Call Number: #{unit.bibl.call_number}", :left => 14 if unit.bibl.call_number?
        @pdf.text "Copy: #{unit.bibl.copy}", :left => 14 if unit.bibl.copy?
        @pdf.text "Volume: #{unit.bibl.volume}", :left => 14 if unit.bibl.volume?
        @pdf.text "Issue: #{unit.bibl.issue}", :left => 14 if unit.bibl.issue?
        @pdf.text "\n"

        @pdf.text "<b>Citation:</b> <i>#{unit.bibl.get_citation}</i>", :left => 10, :inline_format => true
        @pdf.text "\n"
      end

      # TO DO: Create special tables to hold component information
      
    }

    # Page numbering
    string = "page <page> of <total>"
    options = { :at => [@pdf.bounds.right - 150, 0],
              :width => 150,
              :align => :right,
              :start_count_at => 1 }
    @pdf.number_pages string, options

    @pdf 
  end
end