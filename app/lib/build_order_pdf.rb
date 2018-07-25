module BuildOrderPDF
   require 'prawn'
   require 'prawn/table'

   def generate_invoice_pdf(order)
      fee_info = order.fee_payment_info()
      customer = order.customer
      units_in_pdf = []
      order.units.each do |unit|
         if unit.unit_status == 'approved'
            units_in_pdf.push(unit)
         end
      end

      @pdf = Prawn::Document.new
      @pdf.font_families.update(
         "DejaVu" => {
            :normal => "#{Rails.root}/public/fonts/DejaVuSans.ttf",
            :bold => "#{Rails.root}/public/fonts/DejaVuSans-Bold.ttf",
            :italic => "#{Rails.root}/public/fonts/DejaVuSans-Oblique.ttf"
         }
      )

      @pdf.font("DejaVu")
      @pdf.image "#{Rails.root}/app/assets/images/lib_letterhead.jpg", :position => :center, :width => 500
      @pdf.text "Digital Production Group,  University of Virginia Library", :align => :center

      @pdf.text "Post Office Box 400155, Charlottesville, Virginia 22904 U.S.A.", :align => :center
      @pdf.text "\n\n"
      @pdf.text "Order ID: #{order.id}", :align => :right, :font_size => 14
      @pdf.text "\n"
      @pdf.text "Dear #{customer.first_name.capitalize} #{customer.last_name.capitalize}, \n\n"

      if units_in_pdf.length > 1
         @pdf.text "On #{order.date_request_submitted.strftime("%B %d, %Y")} you placed an order with the Digital Production Group of the University of Virginia, Charlottesville, VA.  Your request comprised #{units_in_pdf.length} items.  Below you will find a description of your digital order and how to cite the material for publication."
      else
         @pdf.text "On #{order.date_request_submitted.strftime("%B %d, %Y")} you placed an order with the Digital Production Group of the University of Virginia, Charlottesville, VA.  Your request comprised #{units_in_pdf.length} item.  Below you will find a description of your digital order and how to cite the material for publication."
      end
      @pdf.text "\n"
      if !fee_info.nil?
         fee = fee_info[:fee]
         paid = fee_info[:date_paid].strftime("%F")
         @pdf.text "Our records show that you paid a fee of $#{fee} for this order on #{paid}. ", :inline_format => true
      end

      @pdf.text "\n"
      @pdf.text "Sincerely,", :left => 350
      @pdf.text "\n"
      @pdf.text "Digital Production Group Staff", :left => 350
      # End cover page

      # Begin first page of invoice
      @pdf.start_new_page

      @pdf.text "\n"
      @pdf.text "Digital Order Summary", :align => :center, :font_size => 16
      @pdf.text "\n"

      # Iterate through all the units belonging to this order
      units_in_pdf.each do |unit|
         # For pretty printing purposes, create pagebreak if there is less than 10 lines remaining on the current page.
         @pdf.start_new_page unless @pdf.cursor > 30

         # Add 1 to incrementation because index starts at 0
         item_number = units_in_pdf.index(unit) + 1

         @pdf.text "Item ##{item_number}:", :font_size => 14
         @pdf.text "\n"

         # Begin work on metadata record
         #
         # Output all present fields in record.  Almost all values are optional, so tests are required.
         @pdf.text "Title: #{unit.metadata.title}", :left => 14 if unit.metadata.title?
         @pdf.text "Author: #{unit.metadata.creator_name}", :left => 14 if unit.metadata.creator_name?
         if unit.metadata.type == "SirsiMetadata"
            sirsi = unit.metadata.becomes(unit.metadata.type.constantize)
            @pdf.text "Call Number: #{sirsi.call_number}", :left => 14 if sirsi.call_number?
            @pdf.text "\n"
            @pdf.text "<b>Citation:</b> <i>#{sirsi.get_citation}</i>", :left => 10, :inline_format => true
            @pdf.text "\n"
         end

         output_master_file_data(unit)
      end

      # Page numbering
      string = "page <page> of <total>"
      options = {
         :at => [@pdf.bounds.right - 150, 0],
         :width => 150,
         :align => :right,
         :start_count_at => 1
      }
      @pdf.number_pages string, options
      return @pdf
   end

   def output_master_file_data(unit)
      curr_component = nil
      data = [["Filename", "Title", "Description"]]

      unit.master_files.order(:component_id).order(:filename).each do |mf|
         if mf.component != nil
            if curr_component != mf.component
               if data.size > 1
                  write_mf_table(data)
               end
               curr_component = mf.component
               @pdf.text "#{curr_component.component_type.name.titleize}: #{curr_component.name}\n\n", :font_size => 14
               data = [["Filename", "Title", "Description"]]
            end
         end
         data += [["#{mf.filename}", "#{mf.title}", "#{mf.description}"]]
      end

      if data.size > 1
         write_mf_table(data)
      end
   end

   def write_mf_table(data)
      @pdf.table(data, :column_widths => [140,200,200], :header => true, :row_colors => ["F0F0F0", "FFFFCC"])
      @pdf.text "\n"

      if @pdf.cursor < 30
         @pdf.start_new_page
      end

      @pdf.text "\n"
   end
end
